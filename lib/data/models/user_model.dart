import 'package:equatable/equatable.dart';

enum UserRole {
  user,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String avatarInitials;
  final String? avatarUrl;
  final int points;
  final int rank;
  final int streak;
  final int longestStreak;
  final int challengesCompleted;
  final double averageAccuracy;
  final DateTime joinedAt;
  final UserRole role;
  final bool isDemo;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.avatarInitials,
    this.avatarUrl,
    this.points = 0,
    this.rank = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.challengesCompleted = 0,
    this.averageAccuracy = 0.0,
    required this.joinedAt,
    this.role = UserRole.user,
    this.isDemo = false,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? avatarInitials,
    String? avatarUrl,
    int? points,
    int? rank,
    int? streak,
    int? longestStreak,
    int? challengesCompleted,
    double? averageAccuracy,
    DateTime? joinedAt,
    UserRole? role,
    bool? isDemo,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      joinedAt: joinedAt ?? this.joinedAt,
      role: role ?? this.role,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'avatarInitials': avatarInitials,
      'avatarUrl': avatarUrl,
      'points': points,
      'rank': rank,
      'streak': streak,
      'longestStreak': longestStreak,
      'challengesCompleted': challengesCompleted,
      'averageAccuracy': averageAccuracy,
      'joinedAt': joinedAt.toIso8601String(),
      'role': role.name,
      'isDemo': isDemo,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarInitials: json['avatarInitials'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      challengesCompleted: (json['challengesCompleted'] as num?)?.toInt() ?? 0,
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble() ?? 0.0,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      role: UserRole.fromString(json['role'] as String?),
      isDemo: json['isDemo'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    username,
    email,
    avatarInitials,
    avatarUrl,
    points,
    rank,
    streak,
    longestStreak,
    challengesCompleted,
    averageAccuracy,
    joinedAt,
    role,
    isDemo,
  ];
}
