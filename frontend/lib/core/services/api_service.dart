import 'package:http/http.dart' as http;
import 'package:liftly/core/models/api_response.dart';
import 'dart:convert';

part 'models/auth_response.dart';
part 'models/plan_response.dart';
part 'models/workout_response.dart';
part 'models/stats_response.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.137.79:8080/api';
  // static const String baseUrl = 'http://10.134.195.5:8080/api';
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

  // ==========================================
  // Auth Methods
  // ==========================================

  /// Register with typed response
  static Future<ApiResponse<AuthResponse>> register({
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
      dataParser: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Login with typed response
  static Future<ApiResponse<AuthResponse>> login({
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
      dataParser: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Logout
  static Future<ApiResponse<void>> logout({required String userId}) async {
    return _handleResponseTyped(
      http.post(
        Uri.parse('$baseUrl/auth/logout?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Logout',
      dataParser: (_) {},
    );
  }

  /// Get user profile
  static Future<ApiResponse<AuthResponse>> getUserProfile({
    required String userId,
  }) async {
    return _handleResponseTyped(
      http.get(
        Uri.parse('$baseUrl/auth/user/$userId'),
        headers: _getHeaders(),
      ),
      'Mengambil profil user',
      dataParser: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update user profile
  static Future<ApiResponse<AuthResponse>> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    return _handleResponseTyped(
      http.put(
        Uri.parse('$baseUrl/auth/user/$userId'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ),
      'Update profil user',
      dataParser: (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete user account
  static Future<ApiResponse<void>> deleteUserAccount({
    required String userId,
  }) async {
    return _handleResponseTyped(
      http.delete(
        Uri.parse('$baseUrl/auth/user/$userId'),
        headers: _getHeaders(),
      ),
      'Menghapus akun',
      dataParser: (_) {},
    );
  }

  // ==========================================
  // Plan Methods
  // ==========================================

  /// Create Plan with typed response
  static Future<ApiResponse<PlanResponse>> createPlan({
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
      dataParser: (data) => PlanResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get Plans with typed response
  static Future<ApiResponse<List<PlanResponse>>> getPlans({
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
          return data
              .map((e) => PlanResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic>) {
          return [PlanResponse.fromJson(data)];
        }
        return [];
      },
    );
  }

  /// Get Plan by ID with typed response
  static Future<ApiResponse<PlanResponse>> getPlan({
    required String userId,
    required String planId,
  }) async {
    return _handleResponseTyped(
      http.get(
        Uri.parse('$baseUrl/plans/$planId?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Mengambil plan',
      dataParser: (data) => PlanResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update Plan with typed response
  static Future<ApiResponse<PlanResponse>> updatePlan({
    required String userId,
    required String planId,
    required String name,
    String? description,
    required List<String> exercises,
  }) async {
    return _handleResponseTyped(
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
      dataParser: (data) => PlanResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete Plan with typed response
  static Future<ApiResponse<void>> deletePlan({
    required String userId,
    required String planId,
  }) async {
    return _handleResponseTyped(
      http.delete(
        Uri.parse('$baseUrl/plans/$planId?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Menghapus plan',
      dataParser: (_) {},
    );
  }

  // ============= Workout Logging =============

  /// Create workout with typed response
  static Future<ApiResponse<WorkoutResponse>> createWorkout({
    required String userId,
    required Map<String, dynamic> workoutData,
  }) async {
    return _handleResponseTyped(
      http.post(
        Uri.parse('$baseUrl/workouts?userId=$userId'),
        headers: _getHeaders(),
        body: jsonEncode(workoutData),
      ),
      'Logging workout',
      dataParser: (data) => WorkoutResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get workouts with typed response
  static Future<ApiResponse<List<WorkoutResponse>>> getWorkouts({
    required String userId,
  }) async {
    return _handleResponseTyped(
      http.get(
        Uri.parse('$baseUrl/workouts?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Mengambil workouts',
      dataParser: (data) {
        if (data is List) {
          return data
              .map((e) => WorkoutResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic>) {
          return [WorkoutResponse.fromJson(data)];
        }
        return [];
      },
    );
  }

  /// Update workout with typed response
  static Future<ApiResponse<WorkoutResponse>> updateWorkout({
    required String userId,
    required String workoutId,
    required Map<String, dynamic> workoutData,
  }) async {
    return _handleResponseTyped(
      http.put(
        Uri.parse('$baseUrl/workouts/$workoutId?userId=$userId'),
        headers: _getHeaders(),
        body: jsonEncode(workoutData),
      ),
      'Mengupdate workout',
      dataParser: (data) => WorkoutResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Delete workout with typed response
  static Future<ApiResponse<void>> deleteWorkout({
    required String userId,
    required String workoutId,
  }) async {
    return _handleResponseTyped(
      http.delete(
        Uri.parse('$baseUrl/workouts/$workoutId?userId=$userId'),
        headers: _getHeaders(),
      ),
      'Menghapus workout',
      dataParser: (_) {},
    );
  }

  // ============= Stats =============

  /// Get comprehensive stats summary for a user within a date range
  /// Single API call that returns all needed data (workouts, PR, top exercises, counts, etc)
  static Future<ApiResponse<StatsResponse>> getStatsSummary({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _handleResponseTyped(
      http.post(
        Uri.parse('$baseUrl/stats/summary'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        }),
      ),
      'Mengambil stats summary',
      dataParser: (data) {
        if (data == null) {
          return StatsResponse(
            workouts: [],
            workoutCount: 0,
            totalVolume: 0.0,
            averageDurationMinutes: 0,
            personalRecords: {},
            topExercisesByVolume: {},
            periodStart: '',
            periodEnd: '',
          );
        }
        return StatsResponse.fromJson(data as Map<String, dynamic>);
      },
    );
  }
}