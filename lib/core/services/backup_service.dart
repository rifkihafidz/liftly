import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'data_management_service.dart';
import 'hive_service.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

enum InitializationState { idle, pending, completedWithUser, completedNoUser, failed }

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

  // Error stream for UI feedback
  final _errorController = StreamController<String>.broadcast();
  String? _lastError;

  Stream<String> get onError {
    if (_lastError != null) {
      // Emit last error immediately to new listeners if present
      Future.delayed(Duration.zero, () {
        _errorController.add(_lastError!);
      });
    }
    return _errorController.stream;
  }

  String? get lastError => _lastError;

  GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb && AppConstants.googleClientId.isNotEmpty
        ? AppConstants.googleClientId
        : null,
    scopes: [
      'email',
      'openid',
      drive.DriveApi.driveFileScope,
    ],
  );

  // Track if background silent sign-in is in-flight or timed out (FedCM stuck)
  bool _silentSignInTimedOut = false;
  bool _backgroundSignInInFlight = false;
  Completer<void>? _backgroundSignInCompleter;

  // Cached email for instant UI restore on web (FedCM may be slow/unavailable)
  String? _cachedEmail;
  String? get cachedEmail => _cachedEmail;

  // Cached access token for web session restore (avoids FedCM cooldown issues)
  String? _cachedAccessToken;
  DateTime? _cachedTokenExpiry;
  bool get _hasValidCachedToken =>
      _cachedAccessToken != null &&
      _cachedTokenExpiry != null &&
      DateTime.now().isBefore(_cachedTokenExpiry!);

  /// True if we have a cached session but no live auth and no valid token
  bool get needsReauth =>
      kIsWeb && _cachedEmail != null && _currentUser == null && !_hasValidCachedToken;

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  InitializationState _initState = InitializationState.idle;
  InitializationState get initState => _initState;
  bool get isInitialized =>
      _initState == InitializationState.completedWithUser ||
      _initState == InitializationState.completedNoUser;
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
      if (kIsWeb) {
        // Check if user was previously signed in
        final wasSignedIn = await HiveService.getPreference('gdrive_signed_in');
        AppLogger.debug('BackupService', '[Web] Previous sign-in state: $wasSignedIn');

        if (wasSignedIn == 'true') {
          // Load cached email for instant UI restore
          _cachedEmail = await HiveService.getPreference('gdrive_email');
          // Load cached access token for API calls without re-auth
          _cachedAccessToken = await HiveService.getPreference('gdrive_access_token');
          final expiryStr = await HiveService.getPreference('gdrive_token_expiry');
          if (expiryStr != null && expiryStr.isNotEmpty) {
            _cachedTokenExpiry = DateTime.tryParse(expiryStr);
          }
          AppLogger.debug('BackupService', '[Web] Cached email: $_cachedEmail, token valid: $_hasValidCachedToken');

          // Complete init immediately so the app doesn't block.
          // Show logged-in UI from cache; silent sign-in runs in background.
          _initState = _cachedEmail != null
              ? InitializationState.completedWithUser
              : InitializationState.completedNoUser;
          AppLogger.debug('BackupService', '[Web] Init complete (cached), attempting silent sign-in in background...');
          _attemptWebSilentSignIn();
        } else {
          AppLogger.debug('BackupService', '[Web] No previous session, skipping auto sign-in');
          _initState = InitializationState.completedNoUser;
        }
        return;
      }

      // On mobile platforms, attempt silent sign-in
      _currentUser = await _googleSignIn
          .signInSilently()
          .timeout(const Duration(seconds: 15));

      // Fallback: Check if currentUser is already populated in the plugin
      if (_currentUser == null && _googleSignIn.currentUser != null) {
        _currentUser = _googleSignIn.currentUser;
        AppLogger.debug('BackupService',
            'signInSilently null, but currentUser found: ${_currentUser?.email}');
      }

      if (_currentUser != null) {
        AppLogger.debug('BackupService',
            'Silent sign in successful: ${_currentUser?.email}');
        _initState = InitializationState.completedWithUser;
      } else {
        AppLogger.debug('BackupService', 'Silent sign in returned null (no session)');
        _initState = InitializationState.completedNoUser;
      }
    } catch (e) {
      AppLogger.error('BackupService', 'Silent sign in error', e);
      _lastError = 'Auto-signin error: $e';
      _errorController.add(_lastError!);
      // Check if currentUser is populated despite error
      if (_googleSignIn.currentUser != null) {
        _currentUser = _googleSignIn.currentUser;
        _initState = InitializationState.completedWithUser;
        AppLogger.debug('BackupService',
            'Recovered user from error: ${_currentUser?.email}');
        return;
      }

      // If error occurs, we still want to allow manual sign in
      _initState = InitializationState.completedNoUser;
    } finally {
      _initFuture = null;
    }
  }

  /// Non-blocking silent sign-in for web.
  /// Runs in background — updates _currentUser and _initState via stream.
  /// The Completer allows _ensureSignedIn to wait for this to finish.
  void _attemptWebSilentSignIn() {
    _backgroundSignInInFlight = true;
    _backgroundSignInCompleter = Completer<void>();
    _googleSignIn
        .signInSilently()
        .timeout(const Duration(seconds: 8))
        .then((user) {
      _backgroundSignInInFlight = false;
      if (user != null) {
        _currentUser = user;
        _initState = InitializationState.completedWithUser;
        _cacheAuthToken(); // fire-and-forget
        AppLogger.debug('BackupService',
            '[Web] Background silent sign-in successful: ${user.email}');
      } else if (_googleSignIn.currentUser != null) {
        _currentUser = _googleSignIn.currentUser;
        _initState = InitializationState.completedWithUser;
        AppLogger.debug('BackupService',
            '[Web] Background: currentUser found: ${_currentUser?.email}');
      } else {
        AppLogger.debug('BackupService',
            '[Web] Background silent sign-in returned null');
      }
      _backgroundSignInCompleter?.complete();
      _backgroundSignInCompleter = null;
    }).catchError((e) {
      _backgroundSignInInFlight = false;
      if (e is TimeoutException) {
        AppLogger.debug('BackupService',
            '[Web] Background silent sign-in timed out (FedCM cooldown)');
        _silentSignInTimedOut = true;
      } else {
        AppLogger.debug('BackupService',
            '[Web] Background silent sign-in error: $e');
      }
      _backgroundSignInCompleter?.complete();
      _backgroundSignInCompleter = null;
    });
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    // Ensure initialization is at least attempted
    if (!isInitialized && _initFuture != null) {
      await _initFuture;
    }

    try {
      // If background signInSilently is still in-flight or timed out,
      // the GoogleSignIn instance is stuck. Create a fresh instance.
      if (kIsWeb && (_silentSignInTimedOut || _backgroundSignInInFlight)) {
        AppLogger.debug('BackupService',
            '[Web] Recreating GoogleSignIn instance (inFlight=$_backgroundSignInInFlight, timedOut=$_silentSignInTimedOut)');
        _googleSignIn = GoogleSignIn(
          clientId: AppConstants.googleClientId.isNotEmpty
              ? AppConstants.googleClientId
              : null,
          scopes: [
            'email',
            'openid',
            drive.DriveApi.driveFileScope,
          ],
        );
        _silentSignInTimedOut = false;
        _backgroundSignInInFlight = false;
      }

      AppLogger.debug('BackupService', 'Starting interactive sign-in...');
      _currentUser =
          await _googleSignIn.signIn().timeout(const Duration(minutes: 3));
      
      if (_currentUser != null) {
        AppLogger.debug('BackupService', 'Sign-in successful: ${_currentUser?.email}');
        // Persist sign-in state and email for web session restore
        _cachedEmail = _currentUser!.email;
        await HiveService.savePreference('gdrive_signed_in', 'true');
        await HiveService.savePreference('gdrive_email', _currentUser!.email);
        // Cache access token so reload doesn't need FedCM
        await _cacheAuthToken();
      } else {
        AppLogger.debug('BackupService', 'Sign-in returned null (cancelled?)');
      }
      
      return _currentUser;
    } catch (e) {
      AppLogger.error('BackupService', 'Sign in failed or timed out', e);
      throw BackupException('Sign in failed or timed out: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.debug('BackupService', 'Signing out...');
      await _googleSignIn.disconnect();
      _currentUser = null;
      _cachedEmail = null;
      _cachedAccessToken = null;
      _cachedTokenExpiry = null;
      // Clear persisted sign-in state
      await HiveService.savePreference('gdrive_signed_in', 'false');
      await HiveService.savePreference('gdrive_email', '');
      await HiveService.savePreference('gdrive_access_token', '');
      await HiveService.savePreference('gdrive_token_expiry', '');
      AppLogger.debug('BackupService', 'Sign out complete');
    } catch (e) {
      AppLogger.error('BackupService', 'Sign out failed', e);
    }
  }

  /// Cache the current user's access token to Hive for web session restore.
  Future<void> _cacheAuthToken() async {
    if (_currentUser == null || !kIsWeb) return;
    try {
      final auth = await _currentUser!.authentication;
      _cachedAccessToken = auth.accessToken;
      _cachedTokenExpiry = DateTime.now().add(const Duration(minutes: 55));
      await HiveService.savePreference('gdrive_access_token', _cachedAccessToken!);
      await HiveService.savePreference(
          'gdrive_token_expiry', _cachedTokenExpiry!.toIso8601String());
      AppLogger.debug('BackupService',
          '[Web] Auth token cached (expires: $_cachedTokenExpiry)');
    } catch (e) {
      AppLogger.error('BackupService', 'Failed to cache auth token', e);
    }
  }

  /// Get auth headers — uses live user or falls back to cached token.
  Future<Map<String, String>> _getAuthHeaders() async {
    if (_currentUser != null) {
      final headers = await _currentUser!.authHeaders;
      // Refresh cached token on each successful call
      if (kIsWeb) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        if (token != null && token.isNotEmpty) {
          _cachedAccessToken = token;
          _cachedTokenExpiry = DateTime.now().add(const Duration(minutes: 55));
          // Fire-and-forget save
          HiveService.savePreference('gdrive_access_token', token);
          HiveService.savePreference(
              'gdrive_token_expiry', _cachedTokenExpiry!.toIso8601String());
        }
      }
      return headers;
    }
    if (_hasValidCachedToken) {
      AppLogger.debug('BackupService',
          '[Web] Using cached access token (expires: $_cachedTokenExpiry)');
      return {
        'Authorization': 'Bearer $_cachedAccessToken',
        'X-Goog-AuthUser': '0',
      };
    }
    throw BackupException('No valid authentication available');
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
          AppLogger.debug('BackupService', 'Starting auto-backup...');
          await backupDatabase(silent: true);
        }
      }
    } catch (e) {
      AppLogger.error('BackupService', 'Auto-backup check failed', e);
    }
  }

  /// Re-authenticate if we have a cached session but no live user.
  /// Waits for background sign-in first; only triggers popup if that fails.
  Future<bool> _ensureSignedIn({bool silent = false}) async {
    if (_currentUser != null) return true;
    if (_hasValidCachedToken) return true;
    if (_cachedEmail == null) return false;

    // If background silent sign-in is still running, wait for it first
    if (_backgroundSignInCompleter != null) {
      AppLogger.debug('BackupService',
          'Lazy re-auth: waiting for background sign-in to finish...');
      await _backgroundSignInCompleter!.future;
      // Background sign-in may have succeeded
      if (_currentUser != null) {
        AppLogger.debug('BackupService',
            'Lazy re-auth: background sign-in succeeded, no popup needed');
        return true;
      }
    }

    // Background sign-in failed or timed out — need interactive sign-in
    AppLogger.debug('BackupService',
        'Lazy re-auth: triggering interactive sign-in');
    await signIn();
    return _currentUser != null;
  }

  /// Backup database to Google Drive (now in .xlsx format)
  Future<String?> backupDatabase({
    bool silent = false,
    bool exportOnlyPlans = false,
    Function(double progress, String message)? onProgress,
  }) async {
    if (_currentUser == null) {
      final reauthed = await _ensureSignedIn(silent: silent);
      if (!reauthed) {
        if (!silent) throw BackupException('User not signed in');
        return null;
      }
    }

    // Ensure we have the required scopes (skip if using cached token — scopes already granted)
    AppLogger.debug('BackupService', 'Verifying Drive scope before backup...');
    onProgress?.call(0.05, 'Connecting to Google Drive...');
    if (_currentUser != null) {
      await _ensureDriveScope(silent: silent);
    }

    try {
      AppLogger.debug('BackupService', 'Retrieving auth headers...');
      final headers = await _getAuthHeaders();
      AppLogger.debug('BackupService',
          'Headers retrieved successfully. Initializing client...');
      final client = _GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);

      AppLogger.debug('BackupService', 'Generating Excel bytes...');
      onProgress?.call(0.2, 'Generating backup data...');
      final fileBytes = await DataManagementService.generateExcelBytes(
          exportOnlyPlans: exportOnlyPlans);

      AppLogger.debug('BackupService', 'Accessing backup folder...');
      onProgress?.call(0.6, 'Uploading to Google Drive...');
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

      onProgress?.call(1.0, 'Done!');
      await HiveService.savePreference(
        'last_backup_time',
        DateTime.now().toIso8601String(),
      );

      return result.id;
    } catch (e) {
      AppLogger.error('BackupService', 'Backup failed', e);
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
      AppLogger.error('BackupService', 'Create folder failed', e);
      throw BackupException('Could not access backup folder: ${e.toString()}');
    }
  }

  /// List available backups (.xlsx files)
  Future<List<drive.File>> listBackups() async {
    if (_currentUser == null) {
      final reauthed = await _ensureSignedIn();
      if (!reauthed) throw BackupException('User not signed in');
    }

    if (_currentUser != null) {
      await _ensureDriveScope();
    }

    try {
      final headers = await _getAuthHeaders();
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
      AppLogger.error('BackupService', 'List backups failed', e);
      throw BackupException('Failed to list backups: ${e.toString()}');
    }
  }

  /// Restore data from a specific file ID (.xlsx)
  Future<void> restoreDatabase(
    String fileId, {
    Function(double progress, String message)? onProgress,
  }) async {
    if (_currentUser == null) {
      final reauthed = await _ensureSignedIn();
      if (!reauthed) throw RestoreException('User not signed in');
    }

    if (_currentUser != null) {
      await _ensureDriveScope();
    }

    try {
      final headers = await _getAuthHeaders();
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
      AppLogger.error('BackupService', 'Restore failed', e);
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
      AppLogger.debug('BackupService',
          'Checking for scope: ${drive.DriveApi.driveFileScope}');
      final hasScope =
          await _googleSignIn.canAccessScopes([drive.DriveApi.driveFileScope]);

      AppLogger.debug('BackupService', 'hasScope result: $hasScope');

      if (!hasScope) {
        AppLogger.debug('BackupService',
            'Missing Drive scope, requesting via popup...');
        final granted =
            await _googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
        AppLogger.debug('BackupService', 'requestScopes granted result: $granted');
        if (!granted && !silent) {
          throw BackupException(
              'Permission denied: Google Drive access is required to use this feature.');
        }
      }
    } catch (e) {
      if (e is BackupException) rethrow;
      AppLogger.error('BackupService', 'Scope check/request failed', e);
    }
  }
}
