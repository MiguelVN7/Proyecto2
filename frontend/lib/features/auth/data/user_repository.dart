// Flutter imports:
import 'dart:async';

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Project imports:
import '../domain/user_model.dart';

/// Repository for handling user profile operations in Firestore.
///
/// This class provides a clean interface for user profile CRUD operations
/// including creation, reading, updating, and deletion of user profiles.
class UserRepository {
  /// Firestore instance.
  final FirebaseFirestore _firestore;

  /// Collection name for user documents.
  static const String _usersCollection = 'users';

  /// Creates a user repository with optional Firestore instance.
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the users collection reference.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  /// Creates a new user profile in Firestore.
  ///
  /// Throws [UserRepositoryException] if creation fails.
  /// The user document ID will be the same as the auth UID.
  Future<void> createUser(UserModel user) async {
    try {
      await _usersRef.doc(user.uid).set(user.toFirestore());
      debugPrint('✅ User profile created for ${user.uid}');
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error desconocido al crear usuario: $e',
      );
    }
  }

  /// Gets a user profile by UID.
  ///
  /// Returns null if the user doesn't exist.
  /// Throws [UserRepositoryException] if the operation fails.
  Future<UserModel?> getUser(String uid) async {
    try {
      final DocumentSnapshot doc = await _usersRef.doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al obtener usuario: $e',
      );
    }
  }

  /// Gets a stream of user profile updates.
  ///
  /// Useful for real-time updates of user profile data.
  Stream<UserModel?> getUserStream(String uid) {
    try {
      return _usersRef.doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
    } catch (e) {
      debugPrint('Error creating user stream: $e');
      return Stream.value(null);
    }
  }

  /// Updates a user profile.
  ///
  /// Only updates the provided fields, leaving others unchanged.
  /// Automatically sets the updatedAt timestamp.
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      final Map<String, dynamic> data = {
        ...updates,
        'updatedAt': Timestamp.now(),
      };

      await _usersRef.doc(uid).update(data);
      debugPrint('✅ User profile updated for $uid');
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al actualizar usuario: $e',
      );
    }
  }

  /// Updates the user's email verification status.
  ///
  /// Also updates the status to active when email is verified.
  Future<void> updateEmailVerificationStatus(String uid, bool verified) async {
    try {
      final Map<String, dynamic> updates = {
        'emailVerified': verified,
        'updatedAt': Timestamp.now(),
      };

      // If email is verified, also update status to active
      if (verified) {
        updates['status'] = UserStatus.active.value;
      }

      await _usersRef.doc(uid).update(updates);
      debugPrint('✅ Email verification status updated for $uid: $verified');
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al actualizar estado de verificación: $e',
      );
    }
  }

  /// Updates the user's display name.
  Future<void> updateDisplayName(String uid, String displayName) async {
    await updateUser(uid, {'displayName': displayName});
  }

  /// Updates the user's photo URL.
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await updateUser(uid, {'photoUrl': photoUrl});
  }

  /// Updates the user's phone number.
  Future<void> updatePhoneNumber(String uid, String phoneNumber) async {
    await updateUser(uid, {'phoneNumber': phoneNumber});
  }

  /// Updates the user's role (admin operation).
  Future<void> updateUserRole(String uid, UserRole role) async {
    await updateUser(uid, {'role': role.value});
  }

  /// Updates the user's status (admin operation).
  Future<void> updateUserStatus(String uid, UserStatus status) async {
    await updateUser(uid, {'status': status.value});
  }

  /// Deletes a user profile.
  ///
  /// This should typically be called when a user account is deleted.
  Future<void> deleteUser(String uid) async {
    try {
      await _usersRef.doc(uid).delete();
      debugPrint('✅ User profile deleted for $uid');
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al eliminar usuario: $e',
      );
    }
  }

  /// Checks if a user exists by UID.
  Future<bool> userExists(String uid) async {
    try {
      final DocumentSnapshot doc = await _usersRef.doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  /// Gets users by email (admin operation).
  ///
  /// Note: This requires a Firestore index on the email field.
  Future<List<UserModel>> getUsersByEmail(String email) async {
    try {
      final QuerySnapshot query = await _usersRef
          .where('email', isEqualTo: email)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al buscar usuarios por email: $e',
      );
    }
  }

  /// Gets users by role (admin operation).
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final QuerySnapshot query = await _usersRef
          .where('role', isEqualTo: role.value)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al buscar usuarios por rol: $e',
      );
    }
  }

  /// Gets users by status (admin operation).
  Future<List<UserModel>> getUsersByStatus(UserStatus status) async {
    try {
      final QuerySnapshot query = await _usersRef
          .where('status', isEqualTo: status.value)
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al buscar usuarios por estado: $e',
      );
    }
  }

  /// Gets a paginated list of users (admin operation).
  Future<List<UserModel>> getUsers({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _usersRef.orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot result = await query.limit(limit).get();

      return result.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al obtener lista de usuarios: $e',
      );
    }
  }

  /// Gets unverified users older than the specified duration.
  ///
  /// Useful for cleanup operations to remove stale unverified accounts.
  Future<List<UserModel>> getUnverifiedUsers({
    Duration olderThan = const Duration(days: 1),
  }) async {
    try {
      final DateTime cutoffDate = DateTime.now().subtract(olderThan);

      final QuerySnapshot query = await _usersRef
          .where('emailVerified', isEqualTo: false)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      return query.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error al obtener usuarios no verificados: $e',
      );
    }
  }

  /// Batch delete multiple users (admin operation).
  ///
  /// Useful for cleanup operations.
  Future<void> batchDeleteUsers(List<String> uids) async {
    try {
      final WriteBatch batch = _firestore.batch();

      for (final String uid in uids) {
        batch.delete(_usersRef.doc(uid));
      }

      await batch.commit();
      debugPrint('✅ Batch deleted ${uids.length} users');
    } on FirebaseException catch (e) {
      throw UserRepositoryException.fromFirebase(e);
    } catch (e) {
      throw UserRepositoryException(
        code: 'unknown-error',
        message: 'Error en eliminación por lotes: $e',
      );
    }
  }
}

/// Custom exception class for user repository errors.
class UserRepositoryException implements Exception {
  /// Error code from Firestore or custom code.
  final String code;

  /// User-friendly error message in Spanish.
  final String message;

  /// Creates a user repository exception.
  const UserRepositoryException({
    required this.code,
    required this.message,
  });

  /// Creates a UserRepositoryException from a FirebaseException.
  factory UserRepositoryException.fromFirebase(FirebaseException e) {
    String message;

    switch (e.code) {
      case 'permission-denied':
        message = 'No tienes permisos para realizar esta operación.';
        break;
      case 'not-found':
        message = 'El usuario no fue encontrado.';
        break;
      case 'already-exists':
        message = 'El usuario ya existe.';
        break;
      case 'resource-exhausted':
        message = 'Se ha excedido la cuota de Firestore.';
        break;
      case 'failed-precondition':
        message = 'La operación no se puede realizar en el estado actual.';
        break;
      case 'aborted':
        message = 'La operación fue cancelada debido a un conflicto.';
        break;
      case 'out-of-range':
        message = 'La operación especificó un rango inválido.';
        break;
      case 'unimplemented':
        message = 'Esta operación no está implementada.';
        break;
      case 'internal':
        message = 'Error interno del servidor. Intenta más tarde.';
        break;
      case 'unavailable':
        message = 'El servicio no está disponible. Intenta más tarde.';
        break;
      case 'data-loss':
        message = 'Pérdida de datos irrecuperable.';
        break;
      case 'unauthenticated':
        message = 'No estás autenticado para realizar esta operación.';
        break;
      default:
        message = e.message ?? 'Error desconocido en Firestore.';
    }

    return UserRepositoryException(code: e.code, message: message);
  }

  @override
  String toString() => 'UserRepositoryException(code: $code, message: $message)';
}