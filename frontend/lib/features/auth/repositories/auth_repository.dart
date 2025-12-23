import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';

class AuthRepository {
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await ApiService.login(email: email, password: password);

      return User(
        id: response['id'].toString(),
        email: response['email'],
        token: response['token'],
        firstName: response['firstName'],
        lastName: response['lastName'],
      );
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());
      throw Exception(errorMessage);
    }
  }

  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      return User(
        id: response['id'].toString(),
        email: response['email'],
        token: response['token'],
        firstName: response['firstName'],
        lastName: response['lastName'],
      );
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());
      throw Exception(errorMessage);
    }
  }

  Future<void> logout({required String userId}) async {
    try {
      await ApiService.logout(userId: userId);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  String _parseErrorMessage(String error) {
    // Normalisasi error message
    final errorLower = error.toLowerCase();

    // Check untuk "Invalid email or password" atau variasi lainnya
    if (errorLower.contains('invalid email') ||
        errorLower.contains('invalid password') ||
        errorLower.contains('email or password') ||
        errorLower.contains('wrong password') ||
        errorLower.contains('user not found')) {
      return 'Email atau password salah. Coba lagi.';
    }

    // Check untuk validation errors
    if (error.contains('must be a well-formed email address')) {
      return 'Format email tidak valid. Gunakan email yang benar.';
    }
    if (error.contains('Password is required') || error.contains('password')) {
      return 'Password wajib diisi.';
    }
    if (error.contains('must not be blank') || error.contains('required')) {
      return 'Semua field wajib diisi.';
    }

    // Check untuk connection errors
    if (error.contains('SocketException') ||
        error.contains('Connection refused')) {
      return 'Tidak bisa terhubung ke server. Pastikan backend sedang berjalan.';
    }
    if (error.contains('timeout')) {
      return 'Koneksi timeout. Internet Anda mungkin lambat.';
    }

    // Check untuk already registered
    if (error.contains('already registered') || error.contains('Email sudah')) {
      return 'Email sudah terdaftar. Gunakan email lain atau login.';
    }

    // Default fallback
    return error.isEmpty ? 'Gagal login. Silakan coba lagi.' : error;
  }
}
