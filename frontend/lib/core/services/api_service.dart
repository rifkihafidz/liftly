import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.1.4:8080/api';
  static const Duration timeout = Duration(seconds: 30);

  // Helper method untuk membuat headers dengan token
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Helper method untuk handle response dan error
  static Future<Map<String, dynamic>> _handleResponse(
    Future<http.Response> request,
    String operation,
  ) async {
    try {
      final response = await request.timeout(timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Server tidak merespons dalam 30 detik.');
      });

      // Success response
      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          throw Exception('Response format tidak valid');
        }
      }

      // Error response dengan message
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '$operation gagal';
        throw Exception(errorMessage);
      } on FormatException {
        // Jika tidak bisa parse error response (response body tidak valid JSON)
        switch (response.statusCode) {
          case 400:
            throw Exception('Request tidak valid. Cek kembali data Anda.');
          case 401:
            throw Exception('Akses ditolak. Login kembali diperlukan.');
          case 403:
            throw Exception('Anda tidak memiliki akses ke resource ini.');
          case 404:
            throw Exception('Resource tidak ditemukan.');
          case 409:
            throw Exception('Data sudah ada atau terjadi konflik.');
          case 500:
            throw Exception('Server error. Coba lagi nanti.');
          case 503:
            throw Exception('Server sedang maintenance. Coba lagi nanti.');
          default:
            throw Exception('$operation gagal (Error ${response.statusCode})');
        }
      }
    } on Exception {
      rethrow;
    }
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return _handleResponse(
      http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      ),
      'Registrasi',
    );
  }

  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _handleResponse(
      http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
      'Login',
    );
  }

  // Logout
  static Future<void> logout({
    required String userId,
    required String token,
  }) async {
    await _handleResponse(
      http.post(
        Uri.parse('$baseUrl/auth/logout?userId=$userId'),
        headers: _getHeaders(token: token),
      ),
      'Logout',
    );
  }
}
