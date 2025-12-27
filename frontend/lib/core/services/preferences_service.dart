import 'hive_service.dart';

class PreferencesService {
  /// Set remember me preference with email/password
  static Future<void> setRememberMe(
    bool rememberMe, {
    required String email,
    required String password,
  }) async {
    return HiveService.setRememberMe(rememberMe, email: email, password: password);
  }

  /// Get remember me preference
  static Future<bool> getRememberMe() async {
    return HiveService.getRememberMe();
  }

  /// Get saved email
  static Future<String?> getSavedEmail() async {
    return HiveService.getSavedEmail();
  }

  /// Get saved password
  static Future<String?> getSavedPassword() async {
    return HiveService.getSavedPassword();
  }

  /// Save email only (for registration autofill on next login)
  static Future<void> saveEmailOnly(String email) async {
    return HiveService.saveEmailOnly(email);
  }

  /// Clear all remember me data
  static Future<void> clearRememberMe() async {
    return HiveService.clearRememberMe();
  }
}
