import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String source; // 'login' or 'register'

  const AuthError({
    required this.message,
    this.source = 'login',
  });

  @override
  List<Object?> get props => [message, source];
}

class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({
    this.message = 'Akun berhasil dibuat! Anda akan masuk ke aplikasi.',
  });

  @override
  List<Object?> get props => [message];
}
