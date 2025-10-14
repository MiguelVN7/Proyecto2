// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User model for Firestore authentication and profile management.
///
/// This model represents a user in the EcoTrack application,
/// containing authentication and profile information stored in Firestore.
class UserModel extends Equatable {
  /// Unique user identifier from Firebase Auth.
  final String uid;

  /// User's email address.
  final String email;

  /// User's role in the system.
  final UserRole role;

  /// Current account status.
  final UserStatus status;

  /// Timestamp when the account was created.
  final DateTime createdAt;

  /// Timestamp when the profile was last updated.
  final DateTime? updatedAt;

  /// User's display name (optional).
  final String? displayName;

  /// URL to user's profile photo (optional).
  final String? photoUrl;

  /// User's phone number (optional).
  final String? phoneNumber;

  /// Whether the user's email has been verified.
  final bool emailVerified;

  /// Creates a new user model instance.
  const UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.emailVerified = false,
  });

  /// Creates a new user model for registration.
  ///
  /// This factory constructor creates a user with default values
  /// suitable for new account registration.
  factory UserModel.forRegistration({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      role: UserRole.citizen,
      status: UserStatus.pendingVerification,
      createdAt: DateTime.now(),
      displayName: displayName,
      emailVerified: false,
    );
  }

  /// Creates a user model from Firestore document data.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'citizen'),
      status: UserStatus.fromString(data['status'] ?? 'pending_verification'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      emailVerified: data['emailVerified'] ?? false,
    );
  }

  /// Creates a user model from a map of data.
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'citizen'),
      status: UserStatus.fromString(data['status'] ?? 'pending_verification'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      emailVerified: data['emailVerified'] ?? false,
    );
  }

  /// Converts the user model to a map for Firestore storage.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role.value,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'emailVerified': emailVerified,
    };
  }

  /// Creates a copy of this user model with updated fields.
  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? emailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  /// Marks the user as email verified and active.
  UserModel markAsVerified() {
    return copyWith(
      emailVerified: true,
      status: UserStatus.active,
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if the user can access the application.
  bool get canAccessApp => emailVerified && status == UserStatus.active;

  /// Gets the user's initials for avatar display.
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        role,
        status,
        createdAt,
        updatedAt,
        displayName,
        photoUrl,
        phoneNumber,
        emailVerified,
      ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: $role, status: $status, emailVerified: $emailVerified)';
  }
}

/// Enumeration of user roles in the system.
enum UserRole {
  /// Regular citizen user who can submit reports.
  citizen('citizen', 'Ciudadano'),

  /// Administrator with full system access.
  admin('admin', 'Administrador'),

  /// Moderator with limited administrative privileges.
  moderator('moderator', 'Moderador');

  /// Creates a user role with its value and display name.
  const UserRole(this.value, this.displayName);

  /// The string value stored in Firestore.
  final String value;

  /// Human-readable display name in Spanish.
  final String displayName;

  /// Creates a UserRole from a string value.
  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'citizen':
      default:
        return UserRole.citizen;
    }
  }
}

/// Enumeration of user account statuses.
enum UserStatus {
  /// Account created but email not verified.
  pendingVerification('pending_verification', 'Pendiente de verificación'),

  /// Account active and verified.
  active('active', 'Activo'),

  /// Account temporarily suspended.
  suspended('suspended', 'Suspendido'),

  /// Account banned/deactivated.
  banned('banned', 'Baneado');

  /// Creates a user status with its value and display name.
  const UserStatus(this.value, this.displayName);

  /// The string value stored in Firestore.
  final String value;

  /// Human-readable display name in Spanish.
  final String displayName;

  /// Creates a UserStatus from a string value.
  static UserStatus fromString(String value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'suspended':
        return UserStatus.suspended;
      case 'banned':
        return UserStatus.banned;
      case 'pending_verification':
      default:
        return UserStatus.pendingVerification;
    }
  }
}