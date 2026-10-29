import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../mock/mock_users.dart';
import '../models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel?> getProfile(String userId);
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
  });
  Future<Map<String, dynamic>> getStats(String userId);
  Future<bool> isUsernameTaken(String username, {String? excludeUserId});
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({SharedPreferences? preferences})
    : _prefs = preferences;

  SharedPreferences? _prefs;
  final Map<String, UserModel> _cachedUsers = {};

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<UserModel?> getProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (_cachedUsers.containsKey(userId)) {
      return _cachedUsers[userId];
    }

    final prefs = await _getPrefs();
    final userJson = prefs.getString(AppConstants.keyCurrentUser);
    if (userJson != null) {
      try {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        if (user.id == userId || userId == AppConstants.demoUserId) {
          _cachedUsers[user.id] = user;
          return user;
        }
      } catch (_) {}
    }

    final mock = getMockUserById(userId);
    if (mock != null) {
      _cachedUsers[userId] = mock;
      return mock;
    }

    return null;
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final current = await getProfile(userId) ?? mockDemoUser;

    String initials = current.avatarInitials;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty);
      if (parts.isNotEmpty) {
        initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
      }
    }

    final updated = current.copyWith(
      fullName: fullName?.trim() ?? current.fullName,
      username: username?.trim() ?? current.username,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      avatarInitials: initials,
    );

    _cachedUsers[userId] = updated;

    final prefs = await _getPrefs();
    await prefs.setString(
      AppConstants.keyCurrentUser,
      jsonEncode(updated.toJson()),
    );

    return updated;
  }

  @override
  Future<Map<String, dynamic>> getStats(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final user = await getProfile(userId) ?? mockDemoUser;
    final quizzesCount = (user.challengesCompleted * 0.75).round();
    final codingCount = (user.challengesCompleted * 0.25).round();

    return {
      'points': user.points,
      'rank': user.rank,
      'streak': user.streak,
      'longestStreak': user.longestStreak,
      'challengesCompleted': user.challengesCompleted,
      'averageAccuracy': user.averageAccuracy,
      'quizzesCompleted': quizzesCount,
      'codingCompleted': codingCount,
      'achievementsUnlocked': 6,
      'winRate': user.averageAccuracy,
      'bestCategory': 'Programming',
      'joinedAt': user.joinedAt,
    };
  }

  @override
  Future<bool> isUsernameTaken(String username, {String? excludeUserId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = username.trim().toLowerCase();

    for (final user in allMockUsers) {
      if (excludeUserId != null && user.id == excludeUserId) {
        continue;
      }
      if (user.username.toLowerCase() == normalized) {
        return true;
      }
    }

    for (final user in _cachedUsers.values) {
      if (excludeUserId != null && user.id == excludeUserId) {
        continue;
      }
      if (user.username.toLowerCase() == normalized) {
        return true;
      }
    }

    return false;
  }
}
