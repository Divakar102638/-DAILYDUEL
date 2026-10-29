import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../mock/mock_users.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<UserModel?> getCurrentUser();
  Future<void> saveCurrentUser(UserModel user);
  bool get isLoggedIn;
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;
  UserModel? _currentUser;
  final List<UserModel> _users = List<UserModel>.from(allMockUsers);

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final prefs = await _getPrefs();
    final userJsonStr = prefs.getString(AppConstants.keyCurrentUser);
    if (userJsonStr != null && userJsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap =
            jsonDecode(userJsonStr) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
        return _currentUser;
      } catch (_) {
        await prefs.remove(AppConstants.keyCurrentUser);
      }
    }

    final isDemoLoggedIn = prefs.getBool(AppConstants.keyDemoLoggedIn) ?? false;
    if (isDemoLoggedIn) {
      _currentUser = mockDemoUser;
      return _currentUser;
    }

    return null;
  }

  @override
  Future<void> saveCurrentUser(UserModel user) async {
    _currentUser = user;
    final prefs = await _getPrefs();
    await prefs.setString(
      AppConstants.keyCurrentUser,
      jsonEncode(user.toJson()),
    );
    await prefs.setBool(AppConstants.keyDemoLoggedIn, user.isDemo);
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedEmail.isEmpty) {
      throw Exception('Please enter your email address');
    }

    if (trimmedPassword.isEmpty) {
      throw Exception('Please enter your password');
    }

    UserModel user;

    if (normalizedEmail == AppConstants.demoUserEmail.toLowerCase() &&
        trimmedPassword == 'Demo@1234') {
      user = mockDemoUser;
    } else if (normalizedEmail == 'admin@dailyduel.com' &&
        trimmedPassword == 'Admin@1234') {
      user = mockAdminUser;
    } else if (trimmedPassword.length >= 8) {
      // Allow any valid email with password >= 8 characters
      final existingUserIndex = _users.indexWhere(
        (u) => u.email.toLowerCase() == normalizedEmail,
      );

      if (existingUserIndex != -1) {
        user = _users[existingUserIndex];
      } else {
        final namePart = normalizedEmail.split('@').first;
        final initials = namePart.isNotEmpty
            ? namePart.substring(0, 1).toUpperCase()
            : 'U';

        user = UserModel(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          fullName: namePart.isNotEmpty
              ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
              : 'Test User',
          username: namePart.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_'),
          email: normalizedEmail,
          avatarInitials: initials,
          points: 100,
          rank: 48,
          streak: 1,
          longestStreak: 1,
          challengesCompleted: 0,
          averageAccuracy: 0.0,
          joinedAt: DateTime.now(),
          role: UserRole.user,
          isDemo: false,
        );
        _users.add(user);
      }
    } else {
      throw Exception('Password must be at least 8 characters long');
    }

    _currentUser = user;

    final prefs = await _getPrefs();
    await prefs.setString(
      AppConstants.keyCurrentUser,
      jsonEncode(user.toJson()),
    );
    await prefs.setBool(AppConstants.keyDemoLoggedIn, user.isDemo);
    await prefs.setString(
      AppConstants.keyLastLoginDate,
      DateTime.now().toIso8601String(),
    );

    return user;
  }

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final trimmedFullName = fullName.trim();
    final trimmedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (trimmedFullName.isEmpty) {
      throw Exception('Full name is required');
    }

    if (trimmedUsername.isEmpty) {
      throw Exception('Username is required');
    }

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }

    if (trimmedPassword.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }

    // Check duplicate username
    final isUsernameTaken = _users.any(
      (u) => u.username.toLowerCase() == trimmedUsername,
    );
    if (isUsernameTaken) {
      throw Exception('Username is already taken. Please choose another.');
    }

    // Check duplicate email
    final isEmailTaken = _users.any(
      (u) => u.email.toLowerCase() == normalizedEmail,
    );
    if (isEmailTaken) {
      throw Exception('An account with this email already exists.');
    }

    final initials = trimmedFullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final newUser = UserModel(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: trimmedFullName,
      username: trimmedUsername,
      email: normalizedEmail,
      avatarInitials: initials.isNotEmpty ? initials : 'U',
      points: 50, // Welcome points
      rank: _users.length + 1,
      streak: 1,
      longestStreak: 1,
      challengesCompleted: 0,
      averageAccuracy: 0.0,
      joinedAt: DateTime.now(),
      role: UserRole.user,
      isDemo: false,
    );

    _users.add(newUser);
    _currentUser = newUser;

    final prefs = await _getPrefs();
    await prefs.setString(
      AppConstants.keyCurrentUser,
      jsonEncode(newUser.toJson()),
    );
    await prefs.setBool(AppConstants.keyDemoLoggedIn, false);
    await prefs.setString(
      AppConstants.keyLastLoginDate,
      DateTime.now().toIso8601String(),
    );

    return newUser;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    final prefs = await _getPrefs();
    await prefs.remove(AppConstants.keyCurrentUser);
    await prefs.setBool(AppConstants.keyDemoLoggedIn, false);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }
  }
}
