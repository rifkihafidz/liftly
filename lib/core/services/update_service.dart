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

  static void startPolling() {
    if (!kIsWeb) return;

    // Initial check
    _checkVersion();

    // Poll every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkVersion();
    });
  }

  static Future<void> _checkVersion() async {
    try {
      // Use timestamp to bust cache for version.json
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('version.json?v=$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverVersion = data['version'] as String?;

        if (serverVersion != null && serverVersion != AppConstants.appVersion) {
          if (kDebugMode) {
            print(
                'New version available: $serverVersion. Current: ${AppConstants.appVersion}');
          }
          _timer?.cancel();
          platform.reloadPage();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check version: $e');
      }
    }
  }

  static void stopPolling() {
    _timer?.cancel();
  }
}
