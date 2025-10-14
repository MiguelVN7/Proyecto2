part of 'auth_bloc.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event fired when the authentication system is initialized.
class AuthInitialized extends AuthEvent {
  const AuthInitialized();
}

/// Event fired when user registration is requested.
class AuthRegisterRequested extends AuthEvent {
  /// User's email address.
  final String email;

  /// User's password.
  final String password;

  /// User's display name (optional).
  final String? displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Event fired when user login is requested.
class AuthLoginRequested extends AuthEvent {
  /// User's email address.
  final String email;

  /// User's password.
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Event fired when user logout is requested.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Event fired when email verification is requested.
class AuthEmailVerificationRequested extends AuthEvent {
  const AuthEmailVerificationRequested();
}

/// Event fired when user data should be reloaded.
class AuthUserReloaded extends AuthEvent {
  const AuthUserReloaded();
}

/// Event fired when password reset is requested.
class AuthPasswordResetRequested extends AuthEvent {
  /// Email address to send password reset to.
  final String email;

  const AuthPasswordResetRequested({
    required this.email,
  });

  @override
  List<Object> get props => [email];
}

/// Event fired when the Firebase user changes.
class AuthUserChanged extends AuthEvent {
  /// The new Firebase user (null if signed out).
  final User? user;

  const AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Event fired when user profile is updated.
class AuthProfileUpdated extends AuthEvent {
  /// The updated user model.
  final UserModel user;

  const AuthProfileUpdated(this.user);

  @override
  List<Object> get props => [user];
}