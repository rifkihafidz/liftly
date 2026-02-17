import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

// Conditional import for web implementation
import 'update_service_web.dart' if (dart.library.io) 'update_service_stub.dart'
    as platform;

class UpdateService {
  static Timer? _timer;
  static bool _isChecking = false;

  static void startPolling() {
    if (!kIsWeb) return;

    // Check immediately on startup
    checkVersion();

    // Poll every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      checkVersion();
    });
  }

  static Future<void> checkVersion() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Use timestamp to bust cache for version.json
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('version.json?v=$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverVersion = data['version'] as String?;

        if (serverVersion != null) {
          // Sync check: ignore build numbers (the part after +)
          final cleanServer = serverVersion.split('+')[0];
          final cleanApp = AppConstants.appVersion.split('+')[0];

          if (cleanServer != cleanApp) {
            if (kDebugMode) {
              print('New version available: $cleanServer. Current: $cleanApp');
            }
            _timer?.cancel();
            platform.reloadPage();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check version: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  static void stopPolling() {
    _timer?.cancel();
  }
}
