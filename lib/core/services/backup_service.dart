import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'data_management_service.dart';
import 'sqlite_service.dart';

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

  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Check if user is already signed in silently
  Future<void> init() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('BackupService: Silent sign in failed: $e');
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
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
    } catch (e) {
      debugPrint('BackupService: Sign out failed: $e');
    }
  }

  /// Helper to trigger backup only if auto-backup setting is enabled
  Future<void> backupIfEnabled() async {
    try {
      final enabled = await SQLiteService.getPreference('auto_backup_enabled');
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
  Future<String?> backupDatabase({bool silent = false}) async {
    if (_currentUser == null) {
      if (!silent) throw BackupException('User not signed in');
      return null;
    }

    try {
      final headers = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      final fileBytes = await DataManagementService.generateExcelBytes();

      final folderId = await _getOrCreateBackupFolder(driveApi);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'liftly_data_$timestamp.xlsx';

      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = [folderId];
      driveFile.mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(Stream.value(fileBytes), fileBytes.length),
      );

      await SQLiteService.savePreference(
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
    const folderName = 'Liftly Backup';
    const folderMime = 'application/vnd.google-apps.folder';

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
  Future<void> restoreDatabase(String fileId) async {
    if (_currentUser == null) throw RestoreException('User not signed in');

    try {
      final headers = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      // 1. Download media
      final mediaResponse =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // 2. Read bytes
      final bytes = <int>[];
      await for (final chunk in mediaResponse.stream) {
        bytes.addAll(chunk);
      }

      if (bytes.isEmpty) throw RestoreException('Selected file is empty');

      // 3. Import using DataManagementService
      await DataManagementService.importDataFromBytes(
        Uint8List.fromList(bytes),
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
