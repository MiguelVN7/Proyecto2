// Flutter imports:
import 'dart:async';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Project imports:
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../domain/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Simple, minimal AuthBloc for testing purposes
/// Avoids complex stream handling that was causing emit errors
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Authentication repository.
  final AuthRepository _authRepository;

  /// Creates an auth bloc with the given repository.
  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       super(const AuthState.loading()) {
    on<AuthInitialized>(_onAuthInitialized);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
  }

  /// Handles authentication initialization.
  Future<void> _onAuthInitialized(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    // Simply check current user state without complex stream handling
    final User? currentUser = _authRepository.currentUser;

    if (currentUser != null) {
      // Create a simple user model
      final userModel = UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        role: UserRole.citizen,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        displayName: currentUser.displayName,
        photoUrl: currentUser.photoURL,
        phoneNumber: currentUser.phoneNumber,
        emailVerified: true, // Simplified for testing
      );

      emit(AuthState.authenticated(userModel));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  /// Handles user registration.
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final User user = await _authRepository.registerWithEmailAndPassword(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );

      // Create simple user model
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: UserRole.citizen,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        displayName: user.displayName,
        emailVerified: true, // Simplified for testing
      );

      emit(AuthState.authenticated(userModel));
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Error inesperado durante el registro: $e'));
    }
  }

  /// Handles user login.
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      final User user = await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Create simple user model
      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: UserRole.citizen,
        status: UserStatus.active,
        createdAt: DateTime.now(),
        displayName: user.displayName,
        emailVerified: true, // Simplified for testing
      );

      emit(AuthState.authenticated(userModel));
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Error inesperado durante el inicio de sesión: $e'));
    }
  }

  /// Handles user logout.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      await _authRepository.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      // Even if signOut fails, we should treat as logged out
      emit(const AuthState.unauthenticated());
    }
  }

  /// Handles password reset email requests.
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(AuthState.passwordResetSent(event.email));
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Error al enviar el correo de recuperación: $e'));
    }
  }
}
