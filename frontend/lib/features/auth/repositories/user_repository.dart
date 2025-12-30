import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';

class UserRepository {
  Future<User> getUserProfile({required String userId}) async {
    try {
      final response = await ApiService.getUserProfile(userId: userId);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return User(
        id: response.data!.id,
        email: response.data!.email,
        firstName: response.data!.firstName,
        lastName: response.data!.lastName,
        active: true,
        createdAt: response.data!.token, // Using token field temporarily as API returns it
      );
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<User> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) async {
    try {
      final response = await ApiService.updateUserProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      return User(
        id: response.data!.id,
        email: response.data!.email,
        firstName: response.data!.firstName,
        lastName: response.data!.lastName,
        active: true,
      );
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  Future<void> deleteUserAccount({required String userId}) async {
    try {
      final response = await ApiService.deleteUserAccount(userId: userId);

      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception(_parseErrorMessage(e.toString()));
    }
  }

  String _parseErrorMessage(String error) {
    if (error.contains('Connection refused') ||
        error.contains('Failed host lookup')) {
      return 'Koneksi ke server gagal. Pastikan server sedang berjalan.';
    }
    if (error.contains('SocketException')) {
      return 'Tidak dapat terhubung ke server.';
    }
    if (error.contains('TimeoutException') || error.contains('timeout')) {
      return 'Server tidak merespons. Coba lagi.';
    }
    if (error.contains('Email sudah terdaftar')) {
      return 'Email sudah terdaftar.';
    }
    if (error.contains('Email atau password salah')) {
      return 'Email atau password salah.';
    }
    if (error.contains('User tidak ditemukan')) {
      return 'User tidak ditemukan.';
    }

    // Remove 'Exception: ' prefix if exists
    return error.replaceFirst('Exception: ', '');
  }
}
