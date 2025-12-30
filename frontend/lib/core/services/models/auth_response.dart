part of '../api_service.dart';

class AuthResponse {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? token;

  AuthResponse({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: (json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'token': token,
    };
  }
}
