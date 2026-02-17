import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'data_management_service.dart';
import 'hive_service.dart';
import '../constants/app_constants.dart';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

class RestoreException implements Exception {
  final String message;
  RestoreException(this.message);
  @override
  String toString() => message;
}

class BackupService {
  static final BackupService _instance = BackupService._internal();

  factory BackupService() => _instance;

  BackupService._internal() {
    _googleSignIn.onCurrentUserChanged.listen((user) {
      _currentUser = user;
    });
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConstants.googleClientId : null,
    scopes: [
      'email',
      'openid',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
  bool _initialized = false;
  bool get isInitialized => _initialized;
  Future<void>? _initFuture;

  /// Check if user is already signed in silently
  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _initInternal();
    return _initFuture;
  }

  Future<void> _initInternal() async {
    try {
      // Small delay on Web to ensure GSI is ready
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Add a timeout to prevent hanging on web
      _currentUser = await _googleSignIn
          .signInSilently()
          .timeout(const Duration(seconds: 10));
      debugPrint(
          'BackupService: Silent sign in successful: ${_currentUser?.email}');

      // Only mark initialized if successful (even if user is null)
      _initialized = true;
    } catch (e) {
      debugPrint('BackupService: Silent sign in skipped or timed out: $e');
      // Do NOT mark initialized on error, allowing retry later
    } finally {
      _initFuture = null;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    // Ensure initialization is at least attempted
    if (!_initialized && _initFuture != null) {
      await _initFuture;
    }

    try {
      // Add a 5-minute timeout for interactive login (manual entry + 2FA)
      _currentUser =
          await _googleSignIn.signIn().timeout(const Duration(minutes: 3));
      return _currentUser;
    } catch (e) {
      debugPrint('BackupService: Sign in failed or timed out: $e');
      throw BackupException('Sign in failed or timed out: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null;
    } catch (e) {
      debugPrint('BackupService: Sign out failed: $e');
    }
  }

  /// Helper to trigger backup only if auto-backup setting is enabled
  Future<void> backupIfEnabled() async {
    try {
      final enabled = await HiveService.getPreference('auto_backup_enabled');
      if (enabled == 'true') {
        if (_currentUser == null) {
          await init();
        }
        if (_currentUser != null) {
          debugPrint('BackupService: Starting auto-backup...');
          await backupDatabase(silent: true);
        }
      }
    } catch (e) {
      debugPrint('BackupService: Auto-backup check failed: $e');
    }
  }

  /// Backup database to Google Drive (now in .xlsx format)
  Future<String?> backupDatabase({
    bool silent = false,
    bool exportOnlyPlans = false,
  }) async {
    if (_currentUser == null) {
      if (!silent) throw BackupException('User not signed in');
      return null;
    }

    // Ensure we have the required scopes (especially important on Web)
    debugPrint('BackupService: Verifying Drive scope before backup...');
    await _ensureDriveScope(silent: silent);

    try {
      debugPrint('BackupService: Retrieving auth headers...');
      final headers = await _currentUser!.authHeaders;
      debugPrint(
          'BackupService: Headers retrieved successfully. Initializing client...');
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      debugPrint('BackupService: Generating Excel bytes...');
      final fileBytes = await DataManagementService.generateExcelBytes(
          exportOnlyPlans: exportOnlyPlans);

      debugPrint('BackupService: Accessing backup folder...');
      final folderId = await _getOrCreateBackupFolder(driveApi);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final prefix = exportOnlyPlans ? 'plans' : 'liftly_data';
      final fileName = '${prefix}_$timestamp.xlsx';

      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [folderId];
      driveFile.mimeType = AppConstants.excelMimeType;

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(fileBytes), fileBytes.length),
      );

      await HiveService.savePreference(
        'last_backup_time',
        DateTime.now().toIso8601String(),
      );

      return result.id;
    } catch (e) {
      debugPrint('BackupService: Backup failed: $e');
      if (!silent) {
        throw BackupException('Failed to upload backup: ${e.toString()}');
      }
      return null;
    }
  }

  Future<String> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    const folderName = AppConstants.backupFolderName;
    const folderMime = AppConstants.backupMimeFolder;

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$folderMime' and name = '$folderName' and trashed = false",
        $fields: "files(id, name)",
      );

      if (found.files?.isNotEmpty == true) {
        return found.files!.first.id!;
      }

      final folder = drive.File()
        ..name = folderName
        ..mimeType = folderMime;

      final result = await driveApi.files.create(folder);
      return result.id!;
    } catch (e) {
      debugPrint('BackupService: Create folder failed: $e');
      throw BackupException('Could not access backup folder: ${e.toString()}');
    }
  }

  /// List available backups (.xlsx files)
  Future<List<drive.File>> listBackups() async {
    if (_currentUser == null) throw BackupException('User not signed in');

    await _ensureDriveScope();

    try {
      final headers = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      final folderId = await _getOrCreateBackupFolder(driveApi);

      final fileList = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false and name contains '.xlsx'",
        orderBy: 'createdTime desc',
        $fields: "files(id, name, createdTime, size)",
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('BackupService: List backups failed: $e');
      throw BackupException('Failed to list backups: ${e.toString()}');
    }
  }

  /// Restore data from a specific file ID (.xlsx)
  Future<void> restoreDatabase(
    String fileId, {
    Function(double progress, String message)? onProgress,
  }) async {
    if (_currentUser == null) throw RestoreException('User not signed in');

    await _ensureDriveScope();

    try {
      final headers = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      // 1. Get file metadata for size
      onProgress?.call(0.05, 'Fetching backup info...');
      final fileMetadata = await driveApi.files.get(
        fileId,
        $fields: 'id, name, size',
      ) as drive.File;
      final totalSize = int.tryParse(fileMetadata.size ?? '0') ?? 0;

      // 2. Download media
      onProgress?.call(0.1, 'Downloading backup from Cloud...');
      final mediaResponse = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // 3. Read bytes with progress
      final bytes = <int>[];
      int downloaded = 0;
      await for (final chunk in mediaResponse.stream) {
        bytes.addAll(chunk);
        downloaded += chunk.length;
        if (totalSize > 0) {
          final progress = 0.1 + (0.2 * (downloaded / totalSize));
          onProgress?.call(progress,
              'Downloading (${(downloaded / 1024).toStringAsFixed(1)} KB)...');
        }
      }

      if (bytes.isEmpty) throw RestoreException('Selected file is empty');

      // 4. Import using DataManagementService
      onProgress?.call(0.3, 'Processing backup data...');
      await DataManagementService.importDataFromBytes(
        Uint8List.fromList(bytes),
        onProgress: (p, msg) {
          // Map DataManagementService progress (0.0-1.0) to (0.3-1.0)
          final mappedProgress = 0.3 + (0.7 * p);
          onProgress?.call(mappedProgress, msg);
        },
      );
    } catch (e) {
      debugPrint('BackupService: Restore failed: $e');
      if (e is RestoreException) rethrow;
      throw RestoreException('Restore failed: ${e.toString()}');
    }
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

extension on BackupService {
  Future<void> _ensureDriveScope({bool silent = false}) async {
    try {
      debugPrint(
          'BackupService: Checking for scope: ${drive.DriveApi.driveFileScope}');
      final hasScope =
          await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);

      debugPrint('BackupService: hasScope result: $hasScope');

      if (!hasScope) {
        debugPrint(
            'BackupService: Missing Drive scope, requesting via popup...');
        final granted =
            await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
        debugPrint('BackupService: requestScopes granted result: $granted');
        if (!granted && !silent) {
          throw BackupException(
              'Permission denied: Google Drive access is required to use this feature.');
        }
      }
    } catch (e) {
      debugPrint('BackupService: Scope check/request failed: $e');
    }
  }
}
