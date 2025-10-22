// Flutter imports:
import 'dart:async';

// Package imports:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// Project imports:
import '../domain/user_model.dart';

/// Repository for handling Firebase Authentication operations.
///
/// This class provides a clean interface for authentication operations
/// including registration, login, email verification, and error handling.
class AuthRepository {
  /// Firebase Auth instance.
  final FirebaseAuth _firebaseAuth;

  /// Creates an authentication repository with optional Firebase Auth instance.
  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream of authentication state changes.
  ///
  /// Emits the current Firebase user whenever the authentication state changes.
  /// Returns null when the user is not authenticated.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Stream of user changes including email verification status.
  ///
  /// This stream emits updates when user properties change,
  /// including email verification status.
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  /// Gets the currently authenticated user.
  ///
  /// Returns null if no user is authenticated.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Checks if a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Checks if the current user's email is verified.
  /// TEMPORARILY DISABLED FOR TESTING - Always returns true
  bool get isEmailVerified => true; // currentUser?.emailVerified ?? false;

  /// Registers a new user with email and password.
  ///
  /// Throws [AuthException] if registration fails.
  /// Returns the created Firebase user.
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = result.user;
      if (user == null) {
        throw const AuthException(
          code: 'user-creation-failed',
          message: 'No se pudo crear el usuario',
        );
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Error desconocido durante el registro: $e',
      );
    }
  }

  /// Signs in a user with email and password.
  ///
  /// Throws [AuthException] if login fails.
  /// Returns the authenticated Firebase user.
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = result.user;
      if (user == null) {
        throw const AuthException(
          code: 'sign-in-failed',
          message: 'No se pudo iniciar sesión',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Error desconocido durante el inicio de sesión: $e',
      );
    }
  }

  /// Sends email verification to the current user.
  ///
  /// Throws [AuthException] if sending fails or no user is authenticated.
  Future<void> sendEmailVerification() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        throw const AuthException(
          code: 'no-user',
          message: 'No hay usuario autenticado',
        );
      }

      if (user.emailVerified) {
        throw const AuthException(
          code: 'email-already-verified',
          message: 'El email ya está verificado',
        );
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        code: 'unknown-error',
        message: 'Error al enviar verificación de email: $e',
      );
    }
  }

  /// Reloads the current user to get updated information.
  ///
  /// This is useful for checking if email verification status has changed.
  Future<void> reloadUser() async {
    try {
      final User? user = currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
      // Don't throw here as this is often called in background
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Don't throw here as sign out should always succeed from UI perspective
    }
  }

  /// Sends a password reset email to the specified email address.
  ///
  /// Throws [AuthException] if sending fails.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Ensure password reset email is sent in Spanish
      try {
        await _firebaseAuth.setLanguageCode('es');
      } catch (_) {
        // Non-fatal if setting language fails
      }
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Error al enviar email de recuperación: $e',
      );
    }
  }

  /// Deletes the current user account.
  ///
  /// Throws [AuthException] if deletion fails.
  /// Note: This operation is sensitive and may require recent authentication.
  Future<void> deleteUser() async {
    try {
      final User? user = currentUser;
      if (user == null) {
        throw const AuthException(
          code: 'no-user',
          message: 'No hay usuario autenticado',
        );
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Error al eliminar usuario: $e',
      );
    }
  }

  /// Re-authenticates the current user with email and password.
  ///
  /// This is required before sensitive operations like deleting the account.
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final User? user = currentUser;
      if (user == null || user.email == null) {
        throw const AuthException(
          code: 'no-user',
          message: 'No hay usuario autenticado',
        );
      }

      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'unknown-error',
        message: 'Error en la re-autenticación: $e',
      );
    }
  }

  /// Converts Firebase User to UserModel with current verification status.
  /// TEMPORARILY DISABLED EMAIL VERIFICATION CHECK FOR TESTING
  UserModel? userToUserModel(User? user) {
    if (user == null) return null;

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      role: UserRole.citizen, // Default role
      status: UserStatus
          .active, // user.emailVerified ? UserStatus.active : UserStatus.pendingVerification,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      displayName: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      emailVerified: true, // user.emailVerified,
    );
  }
}

/// Custom exception class for authentication errors.
///
/// Provides user-friendly error messages in Spanish for common
/// Firebase Authentication errors.
class AuthException implements Exception {
  /// Error code from Firebase or custom code.
  final String code;

  /// User-friendly error message in Spanish.
  final String message;

  /// Creates an authentication exception.
  const AuthException({required this.code, required this.message});

  /// Creates an AuthException from a FirebaseAuthException.
  factory AuthException.fromFirebase(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message =
            'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        break;
      case 'email-already-in-use':
        message = 'Este email ya está registrado. Intenta iniciar sesión.';
        break;
      case 'invalid-email':
        message = 'El formato del email es inválido.';
        break;
      case 'operation-not-allowed':
        message = 'El registro con email/contraseña no está habilitado.';
        break;
      case 'user-disabled':
        message = 'Esta cuenta ha sido deshabilitada.';
        break;
      case 'user-not-found':
        message = 'No existe una cuenta con este email.';
        break;
      case 'wrong-password':
        message = 'Contraseña incorrecta.';
        break;
      case 'invalid-credential':
        message = 'Las credenciales son inválidas.';
        break;
      case 'too-many-requests':
        message = 'Demasiados intentos fallidos. Intenta más tarde.';
        break;
      case 'network-request-failed':
        message = 'Error de conexión. Verifica tu internet.';
        break;
      case 'requires-recent-login':
        message = 'Esta operación requiere una autenticación reciente.';
        break;
      case 'email-already-verified':
        message = 'El email ya está verificado.';
        break;
      default:
        message = e.message ?? 'Error de autenticación desconocido.';
    }

    return AuthException(code: e.code, message: message);
  }

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
}
