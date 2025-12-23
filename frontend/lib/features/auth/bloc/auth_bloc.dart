import 'package:flutter/foundation.dart';
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
    debugPrint('=== LOGOUT STARTED ===');
    debugPrint('Current state type: ${state.runtimeType}');

    // Get userId BEFORE changing state
    String? userId;
    if (state is AuthAuthenticated) {
      userId = (state as AuthAuthenticated).user.id;
      debugPrint('✅ Got userId: $userId');
    } else {
      debugPrint('❌ State is not AuthAuthenticated: ${state.runtimeType}');
    }

    emit(const AuthLoading());
    try {
      // Try to logout with userId
      if (userId != null) {
        try {
          debugPrint('Calling logout API with userId: $userId');
          await _authRepository.logout(userId: userId);
          debugPrint('✅ Logout successful from API');
        } catch (apiError) {
          debugPrint('❌ API Logout error: $apiError');
          rethrow;
        }
      } else {
        debugPrint('⚠️ No userId available, skipping API call');
      }
      // Clear saved credentials on logout
      try {
        await PreferencesService.clearRememberMe();
        debugPrint('✅ Preferences cleared');
      } catch (e) {
        debugPrint('⚠️ Error clearing preferences: $e');
      }
      debugPrint('✅ Emitting AuthUnauthenticated');
      emit(const AuthUnauthenticated());
    } catch (e) {
      debugPrint('❌ LOGOUT ERROR: $e');
      // Even if logout fails on backend, clear local auth state
      try {
        await PreferencesService.clearRememberMe();
      } catch (prefError) {
        // Ignore preferences errors
      }
      debugPrint('✅ Emitting AuthUnauthenticated (after error)');
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
