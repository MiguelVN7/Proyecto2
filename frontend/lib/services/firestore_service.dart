// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:image/image.dart' as img;

// Project imports:
import '../models/reporte.dart';
import '../gamification/points_rules.dart';
import '../gamification/achievements.dart';

/// Firestore service for managing environmental reports
///
/// This service handles all Firestore operations for the EcoTrack application,
/// including real-time data synchronization, image storage, and user management.
/// It provides a clean interface for CRUD operations on reports and handles
/// offline functionality and error management.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseStorage _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  // Collection names
  static const String _reportsCollection = 'reports';
  static const String _usersCollection = 'users';
  static const String _fcmTokensCollection = 'fcm_tokens';

  /// Get current user ID for data security
  String? get currentUserId => _auth.currentUser?.uid;

  /// Initialize Firestore service
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('✅ Firestore Service already initialized');
      return;
    }
    try {
      debugPrint('🔥 Initializing Firestore Service...');

      // Enable offline persistence
      _firestore.settings = const Settings(persistenceEnabled: true);

      // Set up authentication state listener
      _auth.authStateChanges().listen((User? user) {
        debugPrint('🔥 Auth state changed: ${user?.uid ?? 'anonymous'}');
      });

      // Initialize Firebase Storage with a corrected bucket if needed
      try {
        final app = Firebase.app();
        var bucket = app.options.storageBucket;
        // Some google-services.json files may include the download domain instead of the bucket domain.
        // Convert *.firebasestorage.app -> *.appspot.com for the bucket resource name.
        if (bucket != null && bucket.endsWith('.firebasestorage.app')) {
          bucket = bucket.replaceFirst('.firebasestorage.app', '.appspot.com');
        }
        if (bucket != null && bucket.isNotEmpty) {
          _storage = FirebaseStorage.instanceFor(bucket: 'gs://$bucket');
          debugPrint('🪣 Using Storage bucket: gs://$bucket');
        } else {
          _storage = FirebaseStorage.instance;
          debugPrint('🪣 Using default Storage bucket');
        }
      } catch (e) {
        // Fallback to default instance if any issue occurs
        _storage = FirebaseStorage.instance;
        debugPrint(
          '⚠️ Could not initialize specific Storage bucket, using default. Error: $e',
        );
      }

      debugPrint('✅ Firestore Service initialized successfully');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing Firestore Service: $e');
      // Continue without offline persistence if it fails
    }
  }

  /// Sign in anonymously for development/testing
  Future<User?> signInAnonymously() async {
    try {
      debugPrint('🔐 Signing in anonymously...');
      final userCredential = await _auth.signInAnonymously();
      debugPrint('✅ Anonymous sign-in successful: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      debugPrint('❌ Error signing in anonymously: $e');
      return null;
    }
  }

  /// Ensure a profile document exists for the current user with sensible defaults
  Future<void> ensureUserProfileSeed({
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final docRef = _firestore.collection(_usersCollection).doc(user.uid);
      final snap = await docRef.get();
      if (!snap.exists) {
        await docRef.set({
          'displayName': displayName ?? user.displayName ?? 'Ciudadano Eco',
          'email': email ?? user.email,
          'photoUrl': photoUrl ?? user.photoURL,
          'points': 0,
          'reports_total': 0,
          'reports_finalized_total': 0,
          'achievementsCompleted': <String>[],
          'achievementsPending': <String>[
            'primer_reporte',
            '5_reportes',
            '10_reportes',
          ],
          'badges': <String>[],
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('❌ Error seeding user profile: $e');
    }
  }

  /// Stream the current user's profile document as a Map
  Stream<Map<String, dynamic>?> userProfileStream({String? uid}) {
    final userId = uid ?? _auth.currentUser?.uid;
    if (userId == null) return Stream<Map<String, dynamic>?>.value(null);
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Update the current user's profile with a partial map
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
    }
  }

  /// Create a new report in Firestore
  /// duplicatePenaltyPercent: optional percentage [0-100] to reduce awarded points if near-duplicate
  Future<String?> createReport(
    Reporte report, {
    int duplicatePenaltyPercent = 0,
  }) async {
    try {
      debugPrint('📝 Creating report in Firestore: ${report.id}');

      // Ensure user is authenticated
      if (currentUserId == null) {
        await signInAnonymously();
      }

      // Add user ID to report
      final reportWithUser = report.copyWith(userId: currentUserId);

      // Basic validation to reduce Firestore failures due to nulls/empties
      if (reportWithUser.tipoResiduo.isEmpty) {
        debugPrint('⚠️ tipoResiduo is empty, defaulting to "Desconocido"');
      }
      if (reportWithUser.prioridad.isEmpty) {
        debugPrint('⚠️ prioridad is empty, defaulting to "Media"');
      }

      final docRef = _firestore.collection(_reportsCollection).doc(report.id);
      final existing = await docRef.get();

      // Prepare base payload; avoid touching created_at if the doc already exists
      final baseData = reportWithUser.toFirestore();
      if (existing.exists) {
        baseData.remove('created_at');
      } else {
        baseData['created_at'] = Timestamp.now();
      }
      baseData['updated_at'] = Timestamp.now();

      // Merge to avoid overwriting previously set award fields
      try {
        await docRef.set(baseData, SetOptions(merge: true));
      } on FirebaseException catch (fe) {
        debugPrint('❌ Firestore write error [${fe.code}]: ${fe.message}');
        // Common case: unauthenticated/permission-denied if auth not ready
        if (fe.code == 'unauthenticated' || fe.code == 'permission-denied') {
          debugPrint('🔁 Attempting anonymous sign-in and retry...');
          await signInAnonymously();
          await docRef.set(baseData, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }

      // Compute points according to HU-14 rules
      final basePoints = PointsRules.computePoints(
        tipoResiduo: reportWithUser.tipoResiduo,
        prioridad: reportWithUser.prioridad,
      );
      int awardedPoints = basePoints;
      if (duplicatePenaltyPercent > 0) {
        awardedPoints = ((basePoints * (100 - duplicatePenaltyPercent)) / 100)
            .round();
      }

      // Award points only if not already awarded for this report
      final alreadyAwarded =
          (existing.data()?['points_awarded'] as num?)?.toInt() != null;
      if (!alreadyAwarded) {
        await docRef.set({
          'points_awarded': awardedPoints,
          'points_awarded_base': basePoints,
          'duplicate_penalty_percent': duplicatePenaltyPercent,
          'points_rule': {
            'tipo_residuo': reportWithUser.tipoResiduo,
            'prioridad': reportWithUser.prioridad,
          },
          'updated_at': Timestamp.now(),
        }, SetOptions(merge: true));

        // Ensure profile exists and increment points and compute expected total locally
        await ensureUserProfileSeed();
        int prevTotal = 0;
        try {
          final userDoc = await _firestore
              .collection(_usersCollection)
              .doc(currentUserId)
              .get();
          final d = userDoc.data();
          if (d != null && d['reports_total'] is num) {
            prevTotal = (d['reports_total'] as num).toInt();
          }
        } catch (_) {}

        await updateUserProfile({
          'points': FieldValue.increment(awardedPoints),
          'reports_total': FieldValue.increment(1),
        });

        // Evaluate and award achievements using the deterministic total we expect after increment
        final afterTotal = prevTotal + 1;
        try {
          await _evaluateAndAwardAchievementsForTotalReports(afterTotal);
        } catch (e) {
          debugPrint('⚠️ Achievement evaluation (totalReports) failed: $e');
        }
      }

      debugPrint('✅ Report created successfully: ${report.id}');
      return report.id;
    } catch (e) {
      debugPrint('❌ Error creating report: $e');
      if (e is FirebaseException) {
        debugPrint(
          '❌ FirebaseException code: ${e.code}, message: ${e.message}',
        );
      }
      return null;
    }
  }

  /// Find reports near a given location within a radius in meters.
  /// This uses a latitude bounding box query and filters by exact distance client-side.
  Future<List<Reporte>> findNearbyReports({
    required double lat,
    required double lng,
    double radiusMeters = 50,
    int limit = 200,
  }) async {
    try {
      final radiusKm = radiusMeters / 1000.0;
      // Approx degrees per km for latitude
      const latDegreeKm = 111.32;
      final deltaLat = radiusKm / latDegreeKm;

      final minLat = lat - deltaLat;
      final maxLat = lat + deltaLat;

      // Range filter on latitude; orderBy required for inequalities on same field
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('location.latitude', isGreaterThanOrEqualTo: minLat)
          .where('location.latitude', isLessThanOrEqualTo: maxLat)
          .orderBy('location.latitude')
          .limit(limit)
          .get();

      final results = <Reporte>[];
      for (final doc in snapshot.docs) {
        try {
          final r = Reporte.fromFirestore(doc);
          final dKm = _calculateDistance(lat, lng, r.lat, r.lng);
          if (dKm <= radiusKm) {
            results.add(r);
          }
        } catch (e) {
          debugPrint('⚠️ Skipping invalid report ${doc.id}: $e');
        }
      }
      return results;
    } catch (e) {
      debugPrint('❌ Error finding nearby reports: $e');
      return [];
    }
  }

  /// Update an existing report
  Future<bool> updateReport(
    String reportId,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('📝 Updating report: $reportId');

      // Add update timestamp
      updates['updated_at'] = Timestamp.now();

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update(updates);

      debugPrint('✅ Report updated successfully: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating report: $e');
      return false;
    }
  }

  /// Update report status
  Future<bool> updateReportStatus(
    String reportId,
    ReportStatus newStatus,
  ) async {
    try {
      debugPrint(
        '🔄 Updating report status: $reportId -> ${newStatus.displayName}',
      );

      // Update estado
      await updateReport(reportId, {'estado': newStatus.displayName});

      // Compute status bonus and award only once per status
      final bonus = PointsRules.statusBonus(newStatus.displayName);
      if (bonus > 0) {
        final docRef = _firestore.collection(_reportsCollection).doc(reportId);
        final snap = await docRef.get();
        final data = snap.data();
        final awarded =
            (data?['status_points_awarded'] as List?)?.cast<String>() ??
            const [];
        final key = newStatus.displayName.toLowerCase();
        if (!awarded.contains(key)) {
          // Update report audit fields
          await docRef.set({
            'status_points_awarded': FieldValue.arrayUnion([key]),
            'status_points_log': FieldValue.arrayUnion([
              {
                'status': newStatus.displayName,
                'points': bonus,
                // Using client timestamp here because serverTimestamp isn't allowed inside arrayUnion payloads
                'awarded_at': Timestamp.now(),
              },
            ]),
            'updated_at': Timestamp.now(),
          }, SetOptions(merge: true));

          // Update user profile points
          await ensureUserProfileSeed();
          final profileUpdates = <String, dynamic>{
            'points': FieldValue.increment(bonus),
          };
          if (newStatus == ReportStatus.completed) {
            profileUpdates['reports_finalized_total'] = FieldValue.increment(1);
          }
          await updateUserProfile(profileUpdates);

          // If finalized, evaluate achievements for finalized reports
          if (newStatus == ReportStatus.completed) {
            // Read previous finalized count to avoid race, then evaluate with override
            int prevFinalized = 0;
            try {
              final userDoc = await _firestore
                  .collection(_usersCollection)
                  .doc(currentUserId)
                  .get();
              final d = userDoc.data();
              if (d != null && d['reports_finalized_total'] is num) {
                prevFinalized = (d['reports_finalized_total'] as num).toInt();
              }
            } catch (_) {}

            try {
              await _evaluateAndAwardAchievementsForFinalized(
                prevFinalized + 1,
              );
            } catch (e) {
              debugPrint('⚠️ Achievement evaluation (finalized) failed: $e');
            }
          }
        }
      }

      debugPrint('✅ Report status updated: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating report status: $e');
      return false;
    }
  }

  /// Get a single report by ID
  Future<Reporte?> getReport(String reportId) async {
    try {
      debugPrint('📖 Getting report: $reportId');

      final doc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get();

      if (doc.exists && doc.data() != null) {
        final report = Reporte.fromFirestore(doc);
        debugPrint('✅ Report retrieved: $reportId');
        return report;
      } else {
        debugPrint('⚠️ Report not found: $reportId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting report: $e');
      return null;
    }
  }

  /// Get all reports with real-time updates
  Stream<List<Reporte>> getReportsStream({int limit = 50, String? userId}) {
    debugPrint('📡 Setting up reports stream (limit: $limit)');

    Query<Map<String, dynamic>> query = _firestore
        .collection(_reportsCollection)
        .orderBy('created_at', descending: true)
        .limit(limit);

    // Filter by user if specified
    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      debugPrint('📡 Reports stream update: ${snapshot.docs.length} reports');

      return snapshot.docs.map((doc) {
        try {
          return Reporte.fromFirestore(doc);
        } catch (e) {
          debugPrint('❌ Error parsing report ${doc.id}: $e');
          // Return a placeholder report for invalid data
          return Reporte.create(
            id: doc.id,
            fotoUrl: '',
            ubicacion: 'Error loading location',
            clasificacion: 'Error',
            tipoResiduo: 'Error',
            lat: 0.0,
            lng: 0.0,
          );
        }
      }).toList();
    });
  }

  /// Get reports by status
  Stream<List<Reporte>> getReportsByStatus(
    ReportStatus status, {
    int limit = 50,
    String? userId,
  }) {
    debugPrint('📡 Setting up reports stream by status: ${status.displayName}');

    Query<Map<String, dynamic>> query = _firestore
        .collection(_reportsCollection)
        .where('estado', isEqualTo: status.displayName)
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (userId != null) {
      query = query.where('user_id', isEqualTo: userId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Reporte.fromFirestore(doc)).toList();
    });
  }

  /// Get reports within a geographic area
  Stream<List<Reporte>> getReportsInArea({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    int limit = 100,
  }) {
    debugPrint(
      '📡 Setting up reports stream in area: $centerLat, $centerLng (${radiusKm}km)',
    );

    // For geographic queries, we'll need to use GeoFlutterFire or implement bounds
    // For now, we'll get all reports and filter client-side (not efficient for production)
    return _firestore
        .collection(_reportsCollection)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Reporte.fromFirestore(doc)).where((
            report,
          ) {
            // Calculate distance (simplified)
            final double lat1 = centerLat;
            final double lon1 = centerLng;
            final double lat2 = report.lat;
            final double lon2 = report.lng;

            // Haversine formula (simplified for demo)
            final double distance = _calculateDistance(lat1, lon1, lat2, lon2);
            return distance <= radiusKm;
          }).toList();
        });
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile, String reportId) async {
    try {
      debugPrint('📤 Uploading image for report: $reportId');

      // Ensure user is authenticated before uploading (many Storage rules require auth)
      if (currentUserId == null) {
        await signInAnonymously();
      }

      final ref = _storage.ref().child(
        'reports/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'report_id': reportId,
            'uploaded_by': currentUserId ?? 'anonymous',
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e, st) {
      debugPrint('❌ Error uploading image: $e');
      debugPrint('🧵 Stack: $st');
      debugPrint(
        'ℹ️ Hints: verify Storage rules permit authenticated users, check project config (google-services.json/GoogleService-Info.plist), and network connectivity.',
      );
      return null;
    }
  }

  /// Create a small base64 thumbnail to store inline in Firestore (fallback when not using Storage)
  Future<String> createBase64Thumbnail(
    File imageFile, {
    int maxSide = 256,
    int quality = 60,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) throw Exception('Unable to decode image');

      final w = original.width;
      final h = original.height;
      final scale = (w > h ? maxSide / w : maxSide / h).clamp(0.0, 1.0);
      final resized = scale < 1.0
          ? img.copyResize(
              original,
              width: (w * scale).round(),
              height: (h * scale).round(),
            )
          : original;
      final jpg = img.encodeJpg(resized, quality: quality);
      final b64 = base64Encode(jpg);
      return 'data:image/jpeg;base64,$b64';
    } catch (e, st) {
      debugPrint('❌ Error creating base64 thumbnail: $e');
      debugPrint('🧵 Stack: $st');
      rethrow;
    }
  }

  /// Delete a report
  Future<bool> deleteReport(String reportId) async {
    try {
      debugPrint('🗑️ Deleting report: $reportId');

      // Get report to check permissions
      final report = await getReport(reportId);
      if (report == null) {
        debugPrint('⚠️ Report not found for deletion: $reportId');
        return false;
      }

      // Check if user can delete (owner or admin)
      if (report.userId != currentUserId && !await _isAdmin()) {
        debugPrint('❌ Unauthorized to delete report: $reportId');
        return false;
      }

      // Delete the report document
      await _firestore.collection(_reportsCollection).doc(reportId).delete();

      // TODO: Delete associated images from Storage

      debugPrint('✅ Report deleted successfully: $reportId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting report: $e');
      return false;
    }
  }

  /// Register FCM token for current user
  Future<bool> registerFCMToken(String token) async {
    try {
      if (currentUserId == null) return false;

      debugPrint('📱 Registering FCM token for user: $currentUserId');

      await _firestore.collection(_fcmTokensCollection).doc(currentUserId).set({
        'token': token,
        'user_id': currentUserId,
        'platform': defaultTargetPlatform.name,
        'updated_at': Timestamp.now(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token registered successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Get FCM tokens for sending notifications
  Future<List<String>> getFCMTokens({String? userId}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(
        _fcmTokensCollection,
      );

      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }

      final snapshot = await query.get();
      final tokens = snapshot.docs
          .map((doc) => doc.data()['token'] as String?)
          .where((token) => token != null)
          .cast<String>()
          .toList();

      debugPrint('📱 Retrieved ${tokens.length} FCM tokens');
      return tokens;
    } catch (e) {
      debugPrint('❌ Error getting FCM tokens: $e');
      return [];
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      debugPrint('📊 Getting Firestore statistics...');

      // Get total reports count
      final reportsSnapshot = await _firestore
          .collection(_reportsCollection)
          .count()
          .get();
      final totalReports = reportsSnapshot.count;

      // Get reports by status
      final statusCounts = <String, int>{};
      for (final status in ReportStatus.values) {
        final statusSnapshot = await _firestore
            .collection(_reportsCollection)
            .where('estado', isEqualTo: status.displayName)
            .count()
            .get();
        statusCounts[status.displayName] = statusSnapshot.count ?? 0;
      }

      // Get total users count
      final usersSnapshot = await _firestore
          .collection(_usersCollection)
          .count()
          .get();
      final totalUsers = usersSnapshot.count ?? 0;

      final stats = {
        'total_reports': totalReports,
        'status_breakdown': statusCounts,
        'total_users': totalUsers,
        'last_updated': DateTime.now().toIso8601String(),
      };

      debugPrint('✅ Statistics retrieved: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Error getting statistics: $e');
      return {};
    }
  }

  /// Helper method to calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Simplified distance calculation for demo purposes
    // In production, use a proper geospatial library
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLon = (lon2 - lon1) * (3.14159 / 180);
    final double a =
        (dLat / 2) * (dLat / 2) +
        (lat1 * (3.14159 / 180)) *
            (lat2 * (3.14159 / 180)) *
            (dLon / 2) *
            (dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371 * c; // Earth's radius in km
  }

  /// Check if current user is admin
  Future<bool> _isAdmin() async {
    // Implement admin check logic
    // For now, return false (no admin privileges)
    return false;
  }

  // Use dart:math functions instead of custom implementations

  // --- Achievements (class-level helpers for cross-library access) ---
  Future<void> reconcileAchievementsFromCounters() async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      final userRef = _firestore.collection(_usersCollection).doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final total = (data['reports_total'] is num)
          ? (data['reports_total'] as num).toInt()
          : 0;
      final finalized = (data['reports_finalized_total'] is num)
          ? (data['reports_finalized_total'] as num).toInt()
          : 0;

      final reached = <Achievement>[];
      for (final a in Achievements.all) {
        if (a.type == AchievementType.totalReports && total >= a.threshold) {
          reached.add(a);
        }
        if (a.type == AchievementType.finalizedReports &&
            finalized >= a.threshold) {
          reached.add(a);
        }
      }
      await _awardAchievementsIfNewInternal(reached);
    } catch (e) {
      debugPrint('⚠️ reconcileAchievementsFromCounters failed: $e');
    }
  }

  Future<void> _evaluateAndAwardAchievementsForTotalReports(int total) async {
    final reached = <Achievement>[];
    for (final a in Achievements.all.where(
      (a) => a.type == AchievementType.totalReports,
    )) {
      if (total >= a.threshold) reached.add(a);
    }
    await _awardAchievementsIfNewInternal(reached);
  }

  Future<void> _evaluateAndAwardAchievementsForFinalized(
    int totalFinalized,
  ) async {
    final reached = <Achievement>[];
    for (final a in Achievements.all.where(
      (a) => a.type == AchievementType.finalizedReports,
    )) {
      if (totalFinalized >= a.threshold) reached.add(a);
    }
    await _awardAchievementsIfNewInternal(reached);
  }

  Future<void> _awardAchievementsIfNewInternal(
    List<Achievement> achieved,
  ) async {
    if (achieved.isEmpty) return;
    final uid = currentUserId;
    if (uid == null) return;
    final userRef = _firestore.collection(_usersCollection).doc(uid);
    Map<String, dynamic> data = const {};
    List<String> completed = const [];
    try {
      final snap = await userRef.get();
      data = snap.data() ?? {};
      completed =
          ((data['achievementsCompleted'] as List?)?.cast<String>()) ??
          <String>[];
    } catch (e) {
      debugPrint('⚠️ Could not read current achievementsCompleted: $e');
    }

    final newlyAwarded = <Achievement>[];
    for (final a in achieved) {
      if (!completed.contains(a.id)) {
        newlyAwarded.add(a);
      }
    }
    if (newlyAwarded.isEmpty) return;

    final completedIds = newlyAwarded.map((e) => e.id).toList();
    final newBadges = newlyAwarded.map((e) => e.title).toList();
    final reward = newlyAwarded.fold<int>(0, (sum, e) => sum + e.rewardPoints);

    try {
      await userRef.set({
        'achievementsCompleted': FieldValue.arrayUnion(completedIds),
        'achievementsPending': FieldValue.arrayRemove(completedIds),
        'badges': FieldValue.arrayUnion(newBadges),
        'points': FieldValue.increment(reward),
        'achievements_log': FieldValue.arrayUnion(
          newlyAwarded
              .map(
                (e) => {
                  'id': e.id,
                  'title': e.title,
                  'points': e.rewardPoints,
                  // Using client timestamp here because serverTimestamp isn't allowed inside arrayUnion payloads
                  'awarded_at': Timestamp.now(),
                },
              )
              .toList(),
        ),
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));
      debugPrint(
        '🏅 Awarded achievements (class): $completedIds (+$reward pts)',
      );
    } on FirebaseException catch (fe) {
      debugPrint(
        '❌ Award achievements (class) failed [${fe.code}]: ${fe.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('❌ Award achievements (class) failed: $e');
      rethrow;
    }
  }
}

/// Extension to add Firestore conversion methods to DateTime
extension DateTimeExtension on DateTime {
  Timestamp toTimestamp() => Timestamp.fromDate(this);
}

/// Extension to add Firestore conversion methods to Timestamp
extension TimestampExtension on Timestamp {
  DateTime toDateTime() => toDate();
}
