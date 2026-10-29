import '../../core/constants/app_constants.dart';
import '../mock/mock_users.dart';
import '../models/leaderboard_entry_model.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard();
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard();
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard();
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard();
  Future<List<LeaderboardEntryModel>> searchLeaderboard(
    String query,
    LeaderboardType type,
  );
  Future<LeaderboardEntryModel?> getCurrentUserRank(LeaderboardType type);
}

class MockLeaderboardRepository implements LeaderboardRepository {
  MockLeaderboardRepository();

  List<LeaderboardEntryModel> _buildGlobalEntries() {
    // Combine demo user and mock leaderboard users
    final users = [mockDemoUser.copyWith(rank: 12), ...mockLeaderboardUsers];

    // Sort descending by points
    users.sort((a, b) => b.points.compareTo(a.points));

    return List.generate(users.length, (index) {
      final u = users[index];
      final isCurrent = u.id == AppConstants.demoUserId;
      return LeaderboardEntryModel(
        rank: index + 1,
        userId: u.id,
        username: u.username,
        fullName: u.fullName,
        avatarInitials: u.avatarInitials,
        avatarUrl: u.avatarUrl,
        points: u.points,
        completedChallenges: u.challengesCompleted,
        streak: u.streak,
        isCurrentUser: isCurrent,
        type: LeaderboardType.global,
      );
    });
  }

  List<LeaderboardEntryModel> _buildWeeklyEntries() {
    final users = [mockDemoUser, ...mockLeaderboardUsers];

    final weeklyEntries = <LeaderboardEntryModel>[];
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      // Generate realistic weekly points based on global points
      final weeklyPoints = (u.points * 0.28).toInt() + ((i * 37) % 150);
      weeklyEntries.add(
        LeaderboardEntryModel(
          rank: 0, // Assigned after sorting
          userId: u.id,
          username: u.username,
          fullName: u.fullName,
          avatarInitials: u.avatarInitials,
          avatarUrl: u.avatarUrl,
          points: weeklyPoints,
          completedChallenges: (u.challengesCompleted * 0.25).round().clamp(
            1,
            40,
          ),
          streak: u.streak,
          isCurrentUser: u.id == AppConstants.demoUserId,
          type: LeaderboardType.weekly,
        ),
      );
    }

    weeklyEntries.sort((a, b) => b.points.compareTo(a.points));
    return List.generate(
      weeklyEntries.length,
      (idx) => weeklyEntries[idx].copyWith(rank: idx + 1),
    );
  }

  List<LeaderboardEntryModel> _buildDailyEntries() {
    final users = [mockDemoUser, ...mockLeaderboardUsers];

    final dailyEntries = <LeaderboardEntryModel>[];
    for (var i = 0; i < users.length; i++) {
      final u = users[i];
      // Generate realistic daily points
      final dailyPoints = 120 + ((u.points ~/ 50) % 280);
      dailyEntries.add(
        LeaderboardEntryModel(
          rank: 0, // Assigned after sorting
          userId: u.id,
          username: u.username,
          fullName: u.fullName,
          avatarInitials: u.avatarInitials,
          avatarUrl: u.avatarUrl,
          points: dailyPoints,
          completedChallenges: (i % 3) + 1,
          streak: u.streak,
          isCurrentUser: u.id == AppConstants.demoUserId,
          type: LeaderboardType.daily,
        ),
      );
    }

    dailyEntries.sort((a, b) => b.points.compareTo(a.points));
    return List.generate(
      dailyEntries.length,
      (idx) => dailyEntries[idx].copyWith(rank: idx + 1),
    );
  }

  List<LeaderboardEntryModel> _buildFriendsEntries() {
    // Subset of users considered "friends"
    final friendIds = {
      AppConstants.demoUserId,
      'user-001',
      'user-003',
      'user-005',
      'user-006',
      'user-008',
    };

    final friendUsers = allMockUsers
        .where((u) => friendIds.contains(u.id))
        .toList();
    friendUsers.sort((a, b) => b.points.compareTo(a.points));

    return List.generate(friendUsers.length, (index) {
      final u = friendUsers[index];
      return LeaderboardEntryModel(
        rank: index + 1,
        userId: u.id,
        username: u.username,
        fullName: u.fullName,
        avatarInitials: u.avatarInitials,
        avatarUrl: u.avatarUrl,
        points: u.points,
        completedChallenges: u.challengesCompleted,
        streak: u.streak,
        isCurrentUser: u.id == AppConstants.demoUserId,
        type: LeaderboardType.friends,
      );
    });
  }

  @override
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _buildGlobalEntries();
  }

  @override
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _buildWeeklyEntries();
  }

  @override
  Future<List<LeaderboardEntryModel>> getDailyLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _buildDailyEntries();
  }

  @override
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _buildFriendsEntries();
  }

  @override
  Future<List<LeaderboardEntryModel>> searchLeaderboard(
    String query,
    LeaderboardType type,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    List<LeaderboardEntryModel> entries;
    switch (type) {
      case LeaderboardType.global:
        entries = _buildGlobalEntries();
        break;
      case LeaderboardType.weekly:
        entries = _buildWeeklyEntries();
        break;
      case LeaderboardType.daily:
        entries = _buildDailyEntries();
        break;
      case LeaderboardType.friends:
        entries = _buildFriendsEntries();
        break;
    }

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;

    return entries.where((e) {
      return e.username.toLowerCase().contains(q) ||
          e.fullName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<LeaderboardEntryModel?> getCurrentUserRank(
    LeaderboardType type,
  ) async {
    List<LeaderboardEntryModel> entries;
    switch (type) {
      case LeaderboardType.global:
        entries = _buildGlobalEntries();
        break;
      case LeaderboardType.weekly:
        entries = _buildWeeklyEntries();
        break;
      case LeaderboardType.daily:
        entries = _buildDailyEntries();
        break;
      case LeaderboardType.friends:
        entries = _buildFriendsEntries();
        break;
    }

    try {
      return entries.firstWhere((e) => e.isCurrentUser);
    } catch (_) {
      return null;
    }
  }
}
