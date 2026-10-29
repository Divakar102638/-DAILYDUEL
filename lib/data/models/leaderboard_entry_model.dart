import 'package:equatable/equatable.dart';

enum LeaderboardType {
  global,
  weekly,
  daily,
  friends;

  String get displayName {
    switch (this) {
      case LeaderboardType.global:
        return 'Global';
      case LeaderboardType.weekly:
        return 'Weekly';
      case LeaderboardType.daily:
        return 'Daily';
      case LeaderboardType.friends:
        return 'Friends';
    }
  }

  static LeaderboardType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'weekly':
        return LeaderboardType.weekly;
      case 'daily':
        return LeaderboardType.daily;
      case 'friends':
        return LeaderboardType.friends;
      case 'global':
      default:
        return LeaderboardType.global;
    }
  }
}

class LeaderboardEntryModel extends Equatable {
  final int rank;
  final String userId;
  final String username;
  final String fullName;
  final String avatarInitials;
  final String? avatarUrl;
  final int points;
  final int completedChallenges;
  final int streak;
  final bool isCurrentUser;
  final LeaderboardType type;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatarInitials,
    this.avatarUrl,
    required this.points,
    this.completedChallenges = 0,
    this.streak = 0,
    this.isCurrentUser = false,
    this.type = LeaderboardType.global,
  });

  bool get isTopThree => rank >= 1 && rank <= 3;

  LeaderboardEntryModel copyWith({
    int? rank,
    String? userId,
    String? username,
    String? fullName,
    String? avatarInitials,
    String? avatarUrl,
    int? points,
    int? completedChallenges,
    int? streak,
    bool? isCurrentUser,
    LeaderboardType? type,
  }) {
    return LeaderboardEntryModel(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      streak: streak ?? this.streak,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'avatarInitials': avatarInitials,
      'avatarUrl': avatarUrl,
      'points': points,
      'completedChallenges': completedChallenges,
      'streak': streak,
      'isCurrentUser': isCurrentUser,
      'type': type.name,
    };
  }

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarInitials: json['avatarInitials'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      completedChallenges: (json['completedChallenges'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      type: LeaderboardType.fromString(json['type'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    rank,
    userId,
    username,
    fullName,
    avatarInitials,
    avatarUrl,
    points,
    completedChallenges,
    streak,
    isCurrentUser,
    type,
  ];
}
