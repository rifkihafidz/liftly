import 'dart:async';
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

enum InitializationState { idle, pending, success, failed }

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
    // Listen to the new authenticationEvents stream to maintain local state
    _googleSignIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        _currentUser = event.user;
        _userChangeController.add(_currentUser);
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _currentUser = null;
        _userChangeController.add(null);
      }
    }, onError: (Object error) {
      debugPrint('BackupService: Authentication stream error: $error');
      _lastError = 'Authentication error: $error';
      _errorController.add(_lastError!);
    });
  }

  // Use the singleton instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Manual state management
  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  // Replicate onCurrentUserChanged for the rest of the app
  final _userChangeController =
      StreamController<GoogleSignInAccount?>.broadcast();
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _userChangeController.stream;

  // Error stream for UI feedback
  final _errorController = StreamController<String>.broadcast();
  String? _lastError;

  Stream<String> get onError {
    if (_lastError != null) {
      Future.delayed(Duration.zero, () {
        _errorController.add(_lastError!);
      });
    }
    return _errorController.stream;
  }

  String? get lastError => _lastError;

  InitializationState _initState = InitializationState.idle;
  InitializationState get initState => _initState;
  bool get isInitialized => _initState == InitializationState.success;
  bool get isInitializing => _initState == InitializationState.pending;

  Future<void>? _initFuture;

  /// Check if user is already signed in silently
  Future<void> init() async {
    if (isInitialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _initInternal();
    return _initFuture;
  }

  Future<void> _initInternal() async {
    _initState = InitializationState.pending;
    try {
      // In 7.2.0, initialize must be called once
      debugPrint('BackupService: Initializing GoogleSignIn singleton...');
      await _googleSignIn.initialize(
        clientId: kIsWeb ? AppConstants.googleClientId : null,
      );

      // Web specific delay to ensure Identity Services are fully hooked
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 3000));
        debugPrint('BackupService: Starting silent sign-in check (Web)...');
      }

      // In 7.0.0+, attemptLightweightAuthentication is the new silent sign-in
      // FedCM on Web typically returns null here and relies on authenticationEvents
      final silentResultFuture =
          _googleSignIn.attemptLightweightAuthentication();
      if (silentResultFuture != null) {
        _currentUser =
            await silentResultFuture.timeout(const Duration(seconds: 20));
        debugPrint(
            'BackupService: Silent sign-in result: ${_currentUser?.email}');
      } else {
        debugPrint(
            'BackupService: Silent sign-in delegated to authenticationEvents (FedCM mode)');
      }

      _initState = InitializationState.success;
    } catch (e) {
      debugPrint('BackupService: Initialization error: $e');
      _lastError = 'Google Sign-In initialization failed: $e';
      _errorController.add(_lastError!);
      _initState = InitializationState.success;
    } finally {
      _initFuture = null;
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    if (!isInitialized) await init();

    try {
      debugPrint('BackupService: Starting interactive sign-in...');
      _currentUser = await _googleSignIn
          .authenticate()
          .timeout(const Duration(minutes: 3));

      _userChangeController.add(_currentUser);
      return _currentUser;
    } catch (e) {
      debugPrint('BackupService: Sign in failed: $e');
      throw BackupException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      _currentUser = null;
      _userChangeController.add(null);
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

    await _ensureDriveScope(silent: silent);

    try {
      debugPrint('BackupService: Obtaining Drive authorization headers...');
      // Use the convenient authorizationHeaders helper from 7.2.0
      final headers =
          await _currentUser!.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveFileScope],
        promptIfNecessary: !silent,
      );

      if (headers == null) {
        throw BackupException(
            'Could not obtain authorization for Google Drive-');
      }

      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      final fileBytes = await DataManagementService.generateExcelBytes(
          exportOnlyPlans: exportOnlyPlans);

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
      final headers =
          await _currentUser!.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveFileScope],
        promptIfNecessary: true,
      );

      if (headers == null) throw BackupException('Authorization failed');

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
      final headers =
          await _currentUser!.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveFileScope],
        promptIfNecessary: true,
      );

      if (headers == null) throw RestoreException('Authorization failed');

      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      onProgress?.call(0.05, 'Fetching backup info...');
      final fileMetadata = await driveApi.files.get(
        fileId,
        $fields: 'id, name, size',
      ) as drive.File;
      final totalSize = int.tryParse(fileMetadata.size ?? '0') ?? 0;

      onProgress?.call(0.1, 'Downloading backup from Cloud...');
      final mediaResponse = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

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

      onProgress?.call(0.3, 'Processing backup data...');
      await DataManagementService.importDataFromBytes(
        Uint8List.fromList(bytes),
        onProgress: (p, msg) {
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
      if (_currentUser == null) return;

      // authorizationHeaders handles both checking and requesting if promptIfNecessary is true
      final headers =
          await _currentUser!.authorizationClient.authorizationHeaders(
        [drive.DriveApi.driveFileScope],
        promptIfNecessary: !silent,
      );

      if (headers != null) {
        debugPrint('BackupService: Drive scope verified.');
      }
    } catch (e) {
      debugPrint('BackupService: Scope authorization failed: $e');
    }
  }
}
