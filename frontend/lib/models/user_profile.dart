// User profile model representing basic info and gamification fields
class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final int points;
  final List<String> achievementsCompleted;
  final List<String> achievementsPending;
  final List<String> badges;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.points = 0,
    this.achievementsCompleted = const [],
    this.achievementsPending = const [],
    this.badges = const [],
  });

  int get level => (points ~/ 100) + 1;
  double get levelProgress => ((points % 100) / 100).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'points': points,
      'achievementsCompleted': achievementsCompleted,
      'achievementsPending': achievementsPending,
      'badges': badges,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      points: (data['points'] as num?)?.toInt() ?? 0,
      achievementsCompleted:
          (data['achievementsCompleted'] as List?)?.cast<String>() ?? const [],
      achievementsPending:
          (data['achievementsPending'] as List?)?.cast<String>() ?? const [],
      badges: (data['badges'] as List?)?.cast<String>() ?? const [],
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    int? points,
    List<String>? achievementsCompleted,
    List<String>? achievementsPending,
    List<String>? badges,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      achievementsCompleted:
          achievementsCompleted ?? this.achievementsCompleted,
      achievementsPending: achievementsPending ?? this.achievementsPending,
      badges: badges ?? this.badges,
    );
  }
}
