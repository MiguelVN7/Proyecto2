part of 'auth_bloc.dart';

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  /// Creates an unauthenticated state.
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// Creates a loading state.
  const factory AuthState.loading() = AuthLoading;

  /// Creates an error state.
  const factory AuthState.error(String message) = AuthError;

  /// Creates an email verification sent state.
  const factory AuthState.emailVerificationSent(UserModel user) = AuthEmailVerificationSent;

  /// Creates an awaiting verification state.
  const factory AuthState.awaitingVerification(UserModel user) = AuthAwaitingVerification;

  /// Creates an authenticated state.
  const factory AuthState.authenticated(UserModel user) = AuthAuthenticated;

  /// Creates a password reset sent state.
  const factory AuthState.passwordResetSent(String email) = AuthPasswordResetSent;
}

/// State when user is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when an authentication operation is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when an authentication error occurs.
class AuthError extends AuthState {
  /// Error message to display to the user.
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

/// State when email verification has been sent after registration.
class AuthEmailVerificationSent extends AuthState {
  /// The user model for the newly registered user.
  final UserModel user;

  const AuthEmailVerificationSent(this.user);

  @override
  List<Object> get props => [user];
}

/// State when user is authenticated but email is not verified.
class AuthAwaitingVerification extends AuthState {
  /// The user model with unverified email.
  final UserModel user;

  /// Whether a loading operation is in progress.
  final bool isLoading;

  /// Optional success message to display.
  final String? message;

  /// Optional error message to display.
  final String? error;

  const AuthAwaitingVerification(
    this.user, {
    this.isLoading = false,
    this.message,
    this.error,
  });

  /// Creates a copy of this state with updated fields.
  AuthAwaitingVerification copyWith({
    UserModel? user,
    bool? isLoading,
    String? message,
    String? error,
  }) {
    return AuthAwaitingVerification(
      user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      message: message,
      error: error,
    );
  }

  @override
  List<Object?> get props => [user, isLoading, message, error];
}

/// State when user is fully authenticated and verified.
class AuthAuthenticated extends AuthState {
  /// The authenticated and verified user.
  final UserModel user;

  const AuthAuthenticated(this.user);

  /// Creates a copy of this state with updated user.
  AuthAuthenticated copyWith({
    UserModel? user,
  }) {
    return AuthAuthenticated(user ?? this.user);
  }

  @override
  List<Object> get props => [user];
}

/// State when password reset email has been sent.
class AuthPasswordResetSent extends AuthState {
  /// Email address where reset was sent.
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object> get props => [email];
}