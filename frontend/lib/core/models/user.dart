import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String token;
  final String? firstName;
  final String? lastName;

  const User({
    required this.id,
    required this.email,
    required this.token,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object?> get props => [id, email, token, firstName, lastName];
}
