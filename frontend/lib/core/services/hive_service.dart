import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String _preferencesBoxName = 'preferences';
  
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  static late Box<dynamic> _preferencesBox;
  
  static bool _isInitialized = false;

  /// Initialize Hive with all boxes
  static Future<void> initHive() async {
    try {
      await Hive.initFlutter();
      
      _preferencesBox = await Hive.openBox<dynamic>(_preferencesBoxName);
      
      _isInitialized = true;
    } catch (e) {
      rethrow;
    }
  }

  /// Check if Hive is initialized
  static bool get isInitialized => _isInitialized;

  /// Close all boxes
  static Future<void> closeHive() async {
    await Hive.close();
  }  // ============= Preferences (Remember Me) =============
  
  static Future<void> setRememberMe(
    bool rememberMe, {
    required String email,
    required String password,
  }) async {
    try {
      if (rememberMe) {
        await _preferencesBox.put(_rememberMeKey, rememberMe);
        await _preferencesBox.put(_emailKey, email);
        await _preferencesBox.put(_passwordKey, password);
      } else {
        await _preferencesBox.put(_rememberMeKey, rememberMe);
        await _preferencesBox.delete(_emailKey);
        await _preferencesBox.delete(_passwordKey);
      }
    } catch (e) {
      // Silent fail
    }
  }

  static Future<bool> getRememberMe() async {
    try {
      final value = _preferencesBox.get(_rememberMeKey);
      return value is bool ? value : false;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getSavedEmail() async {
    try {
      final value = _preferencesBox.get(_emailKey);
      return value is String ? value : null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getSavedPassword() async {
    try {
      final value = _preferencesBox.get(_passwordKey);
      return value is String ? value : null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveEmailOnly(String email) async {
    try {
      await _preferencesBox.put(_emailKey, email);
    } catch (e) {
      // Silent fail
    }
  }

  static Future<void> clearRememberMe() async {
    try {
      await _preferencesBox.delete(_rememberMeKey);
      await _preferencesBox.delete(_emailKey);
      await _preferencesBox.delete(_passwordKey);
    } catch (e) {
      // Silent fail
    }
  }
}
