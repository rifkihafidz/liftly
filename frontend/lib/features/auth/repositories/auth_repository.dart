import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';

class AuthRepository {
  Future<User> login({required String email, required String password}) async {
    try {
      final response = await ApiService.login(email: email, password: password);

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final authData = response.data!;
      return User(
        id: authData.id,
        email: authData.email,
        firstName: authData.firstName,
        lastName: authData.lastName,
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

      if (!response.success || response.data == null) {
        throw Exception(response.message);
      }

      final authData = response.data!;
      return User(
        id: authData.id,
        email: authData.email,
        firstName: authData.firstName,
        lastName: authData.lastName,
      );
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());
      throw Exception(errorMessage);
    }
  }

  Future<void> logout({required String userId}) async {
    try {
      final response = await ApiService.logout(userId: userId);
      if (!response.success) {
        throw Exception(response.message);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  String _parseErrorMessage(String error) {
    // Cek message dari backend
    if (error.contains('Email atau password salah')) {
      return 'Email atau password salah. Coba lagi.';
    }
    if (error.contains('Akun Anda sudah dinonaktifkan')) {
      return 'Akun Anda sudah dinonaktifkan. Hubungi admin.';
    }

    // Check untuk validation errors
    if (error.contains('must be a well-formed email address')) {
      return 'Format email tidak valid. Gunakan email yang benar.';
    }
    if (error.contains('Password is required') || 
        (error.contains('password') && error.contains('required'))) {
      return 'Password harus diisi.';
    }
    if (error.contains('must not be blank') || 
        (error.contains('field') && error.contains('required'))) {
      return 'Semua field harus diisi.';
    }

    // Check untuk connection errors
    if (error.contains('SocketException') ||
        error.contains('Connection refused') ||
        error.contains('Failed to connect')) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (error.contains('timeout')) {
      return 'Koneksi timeout. Internet Anda mungkin lambat, coba lagi.';
    }

    // Check untuk already registered
    if (error.contains('already registered') || 
        error.contains('Email sudah') ||
        error.contains('Email sudah terdaftar')) {
      return 'Email sudah terdaftar. Gunakan email lain atau langsung login.';
    }

    // Check untuk server errors
    if (error.contains('Server error') || error.contains('500')) {
      return 'Server error. Coba lagi dalam beberapa saat.';
    }

    // Check untuk unauthorized/forbidden
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Akses ditolak. Silakan login kembali.';
    }

    // Default fallback - return error dari backend jika user-friendly
    if (error.contains('Exception:')) {
      return error.replaceAll('Exception: ', '').trim();
    }
    
    return error.isEmpty ? 'Terjadi kesalahan. Silakan coba lagi.' : error;
  }
}
