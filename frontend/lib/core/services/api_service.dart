import 'package:http/http.dart' as http;
import 'package:liftly/core/models/api_response.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://192.168.1.5:8080/api';
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> _getHeaders() {
    return {'Content-Type': 'application/json'};
  }

  /// Handle response and return ApiResponse model with parsed data
  static Future<ApiResponse<T>> _handleResponseTyped<T>(
    Future<http.Response> request,
    String operation, {
    required T Function(dynamic) dataParser,
  }) async {
    try {
      final response = await request.timeout(timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Server tidak merespons dalam 30 detik.');
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return ApiResponse<T>.fromJson(
            decoded,
            dataParser: dataParser,
          );
        } catch (e) {
          throw Exception('Response format tidak valid');
        }
      }

      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        return ApiResponse<T>.error(
          message: errorBody['message'] ?? '$operation gagal',
          statusCode: response.statusCode,
          errors: errorBody['errors'] as Map<String, dynamic>?,
        );
      } on FormatException {
        switch (response.statusCode) {
          case 400:
            return ApiResponse<T>.error(
              message: 'Request tidak valid. Cek kembali data Anda.',
              statusCode: 400,
            );
          case 401:
            return ApiResponse<T>.error(
              message: 'Akses ditolak. Login kembali diperlukan.',
              statusCode: 401,
            );
          case 403:
            return ApiResponse<T>.error(
              message: 'Anda tidak memiliki akses ke resource ini.',
              statusCode: 403,
            );
          case 404:
            return ApiResponse<T>.error(
              message: 'Resource tidak ditemukan.',
              statusCode: 404,
            );
          case 409:
            return ApiResponse<T>.error(
              message: 'Data sudah ada atau terjadi konflik.',
              statusCode: 409,
            );
          case 500:
            return ApiResponse<T>.error(
              message: 'Server error. Coba lagi nanti.',
              statusCode: 500,
            );
          case 503:
            return ApiResponse<T>.error(
              message: 'Server sedang maintenance. Coba lagi nanti.',
              statusCode: 503,
            );
          default:
            return ApiResponse<T>.error(
              message: '$operation gagal (Error ${response.statusCode})',
              statusCode: response.statusCode,
            );
        }
      }
    } catch (e) {
      return ApiResponse<T>.error(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  /// Legacy method - Handle response and return only data (for backward compatibility)
  static Future<Map<String, dynamic>> _handleResponse(
    Future<http.Response> request,
    String operation,
  ) async {
    try {
      final response = await request.timeout(timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Server tidak merespons dalam 30 detik.');
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          // Extract data from the standardized response format
          if (decoded['success'] == true && decoded['data'] != null) {
            return decoded['data'] as Map<String, dynamic>;
          }
          // If no data field, return the decoded response
          return decoded;
        } catch (e) {
          throw Exception('Response format tidak valid');
        }
      }

      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? '$operation gagal';
        throw Exception(errorMessage);
      } on FormatException {
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
  static Future<void> logout({required String userId}) async {
    await _handleResponse(
      http.post(
        Uri.parse('$baseUrl/auth/logout?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Logout',
    );
  }

  // Create Plan
  static Future<Map<String, dynamic>> createPlan({
    required String userId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    return _handleResponse(
      http.post(
        Uri.parse('$baseUrl/plans?userId=$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'exercises': exercises,
        }),
      ),
      'Membuat plan',
    );
  }

  // Get Plans
  static Future<List<Map<String, dynamic>>> getPlans({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plans?userId=$userId'),
        headers: _getHeaders(),
      ).timeout(timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Server tidak merespons dalam 30 detik.');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          
          // Extract data from standardized response format
          if (decoded['success'] == true && decoded['data'] != null) {
            final data = decoded['data'];
            if (data is List) {
              return List<Map<String, dynamic>>.from(data);
            } else if (data is Map<String, dynamic>) {
              return [data];
            }
          }
          return [];
        } catch (e) {
          throw Exception('Response format tidak valid');
        }
      }

      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Mengambil plans gagal';
        throw Exception(errorMessage);
      } on FormatException {
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
            throw Exception('Mengambil plans gagal (Error ${response.statusCode})');
        }
      }
    } on Exception {
      rethrow;
    }
  }

  // Get Plan by ID
  static Future<Map<String, dynamic>> getPlan({
    required String userId,
    required String planId,
  }) async {
    return _handleResponse(
      http.get(
        Uri.parse('$baseUrl/plans/$planId?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Mengambil plan',
    );
  }

  // Update Plan
  static Future<Map<String, dynamic>> updatePlan({
    required String userId,
    required String planId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    return _handleResponse(
      http.put(
        Uri.parse('$baseUrl/plans/$planId?userId=$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'exercises': exercises,
        }),
      ),
      'Mengupdate plan',
    );
  }

  // Delete Plan
  static Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/plans/$planId?userId=$userId'),
        headers: _getHeaders(),
      ).timeout(timeout, onTimeout: () {
        throw Exception('Koneksi timeout. Server tidak merespons dalam 30 detik.');
      });

      if (response.statusCode == 200) {
        // Success - standardized response format
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == true) {
            return;
          }
        } catch (e) {
          // If parsing fails but status is 200, still consider it success
          return;
        }
      }

      // Error response
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Menghapus plan gagal';
        throw Exception(errorMessage);
      } on FormatException {
        switch (response.statusCode) {
          case 400:
            throw Exception('Request tidak valid. Cek kembali data Anda.');
          case 401:
            throw Exception('Akses ditolak. Login kembali diperlukan.');
          case 403:
            throw Exception('Anda tidak memiliki akses ke resource ini.');
          case 404:
            throw Exception('Plan tidak ditemukan.');
          case 500:
            throw Exception('Server error. Coba lagi nanti.');
          case 503:
            throw Exception('Server sedang maintenance. Coba lagi nanti.');
          default:
            throw Exception('Menghapus plan gagal (Error ${response.statusCode})');
        }
      }
    } on Exception {
      rethrow;
    }
  }

  // ==========================================
  // NEW METHODS - Using ApiResponse<T> model
  // ==========================================

  /// Register with typed response
  static Future<ApiResponse<Map<String, dynamic>>> registerTyped({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return _handleResponseTyped(
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
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Login with typed response
  static Future<ApiResponse<Map<String, dynamic>>> loginTyped({
    required String email,
    required String password,
  }) async {
    return _handleResponseTyped(
      http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      ),
      'Login',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Create Plan with typed response
  static Future<ApiResponse<Map<String, dynamic>>> createPlanTyped({
    required String userId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    return _handleResponseTyped(
      http.post(
        Uri.parse('$baseUrl/plans?userId=$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'exercises': exercises,
        }),
      ),
      'Membuat plan',
      dataParser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get Plans with typed response
  static Future<ApiResponse<List<Map<String, dynamic>>>> getPlansTyped({
    required String userId,
  }) async {
    return _handleResponseTyped(
      http.get(
        Uri.parse('$baseUrl/plans?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Mengambil plans',
      dataParser: (data) {
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          return [data];
        }
        return [];
      },
    );
  }
}

