import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/preferences_service.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      // Clear saved password & remember me on successful registration
      await PreferencesService.clearRememberMe();
      // Save email for next login convenience
      await PreferencesService.saveEmailOnly(user.email);
      // Show success message then authenticate
      emit(const AuthRegistrationSuccess());
      // Delay sebentar untuk user bisa lihat success message
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      final errorMessage = _parseErrorMessage(e.toString());
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Get userId BEFORE changing state
    String? userId;
    if (state is AuthAuthenticated) {
      final authState = state as AuthAuthenticated;
      userId = authState.user.id;
    }

    emit(const AuthLoading());
    try {
      // Try to logout with userId
      if (userId != null) {
        try {
          await _authRepository.logout(userId: userId);
        } catch (apiError) {
          rethrow;
        }
      }
      // Clear saved credentials on logout
      try {
        await PreferencesService.clearRememberMe();
      } catch (e) {
        // Ignore
      }
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails on backend, clear local auth state
      try {
        await PreferencesService.clearRememberMe();
      } catch (prefError) {
        // Ignore preferences errors
      }
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: Check if user has valid token
    emit(const AuthUnauthenticated());
  }

  String _parseErrorMessage(String error) {
    // Error message sudah di-parse oleh AuthRepository
    // Tinggal pass ke UI
    if (error.contains('Exception: ')) {
      return error.replaceAll('Exception: ', '');
    }
    return error;
  }
}
