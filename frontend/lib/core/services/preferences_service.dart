import 'sqlite_service.dart';

class PreferencesService {
  static const String _rememberMeKey = 'remember_me';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';

  /// Set remember me preference with email/password
  static Future<void> setRememberMe(
    bool rememberMe, {
    required String email,
    required String password,
  }) async {
    try {
      if (rememberMe) {
        await SQLiteService.savePreference(_rememberMeKey, rememberMe.toString());
        await SQLiteService.savePreference(_emailKey, email);
        await SQLiteService.savePreference(_passwordKey, password);
      } else {
        await SQLiteService.savePreference(_rememberMeKey, rememberMe.toString());
        await SQLiteService.deletePreference(_emailKey);
        await SQLiteService.deletePreference(_passwordKey);
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    try {
      final value = await SQLiteService.getPreference(_rememberMeKey);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    try {
      return await SQLiteService.getPreference(_emailKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    try {
      return await SQLiteService.getPreference(_passwordKey);
    } catch (e) {
      return null;
    }
  }

  /// Save email only (for registration autofill on next login)
  static Future<void> saveEmailOnly(String email) async {
    try {
      await SQLiteService.savePreference(_emailKey, email);
    } catch (e) {
      // Silent fail
    }
  }

  /// Clear all remember me data
  static Future<void> clearRememberMe() async {
    try {
      await SQLiteService.deletePreference(_rememberMeKey);
      await SQLiteService.deletePreference(_emailKey);
      await SQLiteService.deletePreference(_passwordKey);
    } catch (e) {
      // Silent fail
    }
  }
}
