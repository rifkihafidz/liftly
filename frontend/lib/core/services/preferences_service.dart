import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  static Future<void> setRememberMe(
    bool rememberMe, {
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('SharedPrefs: Setting remember_me=$rememberMe, email=$email');
      final prefs = await SharedPreferences.getInstance();
      debugPrint('SharedPrefs: Got instance, setting values...');

      await prefs.setBool(_rememberMeKey, rememberMe);
      debugPrint('✅ Set _rememberMeKey=$rememberMe');

      if (rememberMe) {
        await prefs.setString(_emailKey, email);
        debugPrint('✅ Set _emailKey=$email');

        await prefs.setString(_passwordKey, password);
        debugPrint('✅ Set _passwordKey (length=${password.length})');
      } else {
        await prefs.remove(_emailKey);
        debugPrint('✅ Removed _emailKey');

        await prefs.remove(_passwordKey);
        debugPrint('✅ Removed _passwordKey');
      }
      debugPrint('✅ All preferences saved successfully');
    } catch (e) {
      debugPrint('❌ SharedPreferences error: $e');
      // Don't rethrow - just silently fail
    }
  }

  static Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
      return false;
    }
  }

  static Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
      return null;
    }
  }

  static Future<String?> getSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_passwordKey);
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
      return null;
    }
  }

  static Future<void> clearRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_passwordKey);
    } catch (e) {
      debugPrint('SharedPreferences error: $e');
      // Don't rethrow - clearing is not critical
    }
  }
}
