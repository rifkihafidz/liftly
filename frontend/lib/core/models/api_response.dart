import 'package:equatable/equatable.dart';

/// Generic API Response model that matches the backend standardized response format
///
/// This model handles all types of responses from the backend API with a consistent structure:
/// - success: boolean indicating if the operation was successful
/// - statusCode: HTTP status code
/// - message: descriptive message about the operation
/// - data: generic type T for response payload (can be any type)
/// - errors: optional map of field validation errors
///
/// Example Usage:
/// ```dart
/// // For user login response
/// final response = await ApiService.loginTyped(email: 'user@test.com', password: 'pass');
/// if (response.success) {
///   final userData = response.data; // Map<String, dynamic>
///   print('User ID: ${userData['id']}');
/// } else {
///   print('Error: ${response.message}');
/// }
///
/// // For plans list response
/// final plansResponse = await ApiService.getPlansTyped(userId: '1');
/// if (plansResponse.success) {
///   final plans = plansResponse.data; // List<Map<String, dynamic>>
///   for (final plan in plans) {
///     print('Plan: ${plan['name']}');
///   }
/// }
/// ```
class ApiResponse<T> extends Equatable {
  /// Whether the operation was successful
  final bool success;
  
  /// HTTP status code from the server
  final int statusCode;
  
  /// Descriptive message about the operation
  final String message;
  
  /// Response payload (generic type, can be any type)
  final T? data;
  
  /// Field validation errors (optional)
  /// Only present in validation error responses
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
  });

  /// Create a success response
  factory ApiResponse.success({
    required T data,
    required String message,
    int statusCode = 200,
  }) {
    return ApiResponse(
      success: true,
      statusCode: statusCode,
      message: message,
      data: data,
      errors: null,
    );
  }

  /// Create an error response
  factory ApiResponse.error({
    required String message,
    int statusCode = 500,
    Map<String, dynamic>? errors,
  }) {
    return ApiResponse(
      success: false,
      statusCode: statusCode,
      message: message,
      data: null,
      errors: errors,
    );
  }

  /// Parse from JSON map
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    required T Function(dynamic)? dataParser,
  }) {
    final success = json['success'] as bool? ?? false;
    final statusCode = json['statusCode'] as int? ?? 500;
    final message = json['message'] as String? ?? '';
    final rawData = json['data'];
    final errors = json['errors'] as Map<String, dynamic>?;

    T? parsedData;
    if (rawData != null && dataParser != null) {
      parsedData = dataParser(rawData);
    }

    return ApiResponse(
      success: success,
      statusCode: statusCode,
      message: message,
      data: parsedData,
      errors: errors,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'statusCode': statusCode,
      'message': message,
      if (data != null) 'data': data,
      if (errors != null) 'errors': errors,
    };
  }

  @override
  List<Object?> get props => [success, statusCode, message, data, errors];
}
