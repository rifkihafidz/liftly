import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool? active;
  final String? createdAt;
  final String? updatedAt;

  const User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.active,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, email, firstName, lastName, active, createdAt, updatedAt];

  // Copy with method for updating user
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Factory for JSON parsing
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      active: json['active'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'active': active,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Get full name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    return '$first $last'.trim();
  }
}

