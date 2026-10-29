import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/challenge_model.dart';
import '../../data/models/leaderboard_entry_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/quiz_attempt_model.dart';
import '../../data/models/settings_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/challenge_repository.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/quiz_repository.dart';
import '../../data/repositories/settings_repository.dart';

// ============================================================================
// REPOSITORIES
// ============================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return MockChallengeRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return MockLeaderboardRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return MockNotificationRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return MockAchievementRepository();
});

final settingsRepositoryProvider = Provider<LocalSettingsRepository>((ref) {
  return LocalSettingsRepository();
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return MockQuizRepository();
});

// ============================================================================
// AUTH STATE & NOTIFIER
// ============================================================================

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    loadUser();
  }

  final AuthRepository _authRepository;

  Future<void> loadUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserModel> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signIn(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUp(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _authRepository.sendPasswordReset(email);
  }

  Future<void> updateCurrentUser(UserModel user) async {
    await _authRepository.saveCurrentUser(user);
    state = AsyncValue.data(user);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref.watch(authRepositoryProvider));
    });

// ============================================================================
// SETTINGS & THEME
// ============================================================================

class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier(this._settingsRepository)
    : super(SettingsModel.defaultSettings()) {
    loadSettings();
  }

  final LocalSettingsRepository _settingsRepository;

  Future<void> loadSettings() async {
    try {
      final loaded = await _settingsRepository.getSettings();
      state = loaded;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'DailyDuel settings',
          context: ErrorDescription('while loading local settings'),
        ),
      );
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = state.copyWith(themeMode: mode);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final updated = state.copyWith(notificationsEnabled: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setDailyChallengeReminder(bool enabled) async {
    final updated = state.copyWith(dailyChallengeReminder: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setAchievementAlerts(bool enabled) async {
    final updated = state.copyWith(achievementAlerts: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setLeaderboardUpdates(bool enabled) async {
    final updated = state.copyWith(leaderboardUpdates: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setSoundEffects(bool enabled) async {
    final updated = state.copyWith(soundEffects: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final updated = state.copyWith(hapticFeedback: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setPrivacyShowProfile(bool enabled) async {
    final updated = state.copyWith(privacyShowProfile: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }

  Future<void> setPrivacyShowStats(bool enabled) async {
    final updated = state.copyWith(privacyShowStats: enabled);
    state = updated;
    await _settingsRepository.saveSettings(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) {
    return SettingsNotifier(ref.watch(settingsRepositoryProvider));
  },
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  switch (settings.themeMode) {
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});

// ============================================================================
// CHALLENGES
// ============================================================================

final dailyChallengesProvider = FutureProvider<List<ChallengeModel>>((
  ref,
) async {
  return ref.watch(challengeRepositoryProvider).getDailyChallenges();
});

final allChallengesProvider = FutureProvider<List<ChallengeModel>>((ref) async {
  return ref.watch(challengeRepositoryProvider).getAllChallenges();
});

// ============================================================================
// LEADERBOARD
// ============================================================================

final globalLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((
  ref,
) async {
  return ref.watch(leaderboardRepositoryProvider).getGlobalLeaderboard();
});

final weeklyLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((
  ref,
) async {
  return ref.watch(leaderboardRepositoryProvider).getWeeklyLeaderboard();
});

final dailyLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((
  ref,
) async {
  return ref.watch(leaderboardRepositoryProvider).getDailyLeaderboard();
});

final friendsLeaderboardProvider = FutureProvider<List<LeaderboardEntryModel>>((
  ref,
) async {
  return ref.watch(leaderboardRepositoryProvider).getFriendsLeaderboard();
});

// ============================================================================
// NOTIFICATIONS
// ============================================================================

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationsNotifier(this._notificationRepository)
    : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  final NotificationRepository _notificationRepository;

  Future<void> loadNotifications() async {
    try {
      final list = await _notificationRepository.getNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await _notificationRepository.markAsRead(id);
    state.whenData((items) {
      state = AsyncValue.data(
        items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );
    });
  }

  Future<void> markAllAsRead() async {
    await _notificationRepository.markAllAsRead();
    state.whenData((items) {
      state = AsyncValue.data(
        items.map((n) => n.copyWith(isRead: true)).toList(),
      );
    });
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _notificationRepository.addNotification(notification);
    state.whenData((items) {
      state = AsyncValue.data([notification, ...items]);
    });
  }
}

final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<NotificationModel>>
    >((ref) {
      return NotificationsNotifier(ref.watch(notificationRepositoryProvider));
    });

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// ============================================================================
// ACHIEVEMENTS
// ============================================================================

final achievementsProvider = FutureProvider<List<AchievementModel>>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  final userId = user?.id ?? AppConstants.demoUserId;
  return ref.watch(achievementRepositoryProvider).getAchievements(userId);
});

// ============================================================================
// ACTIVITY
// ============================================================================

class ActivityNotifier extends StateNotifier<List<ActivityModel>> {
  ActivityNotifier() : super(_defaultActivities());

  static List<ActivityModel> _defaultActivities() {
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'act-001',
        challengeId: 'challenge-net-01',
        challengeTitle: 'Networking & Protocols Sprint',
        userId: AppConstants.demoUserId,
        type: ActivityType.quiz,
        status: ActivityStatus.completed,
        score: 90,
        accuracy: 90.0,
        pointsEarned: 90,
        timeTakenSeconds: 310,
        completedAt: now.subtract(const Duration(hours: 4)),
        category: 'Networking',
        difficulty: 'Beginner',
      ),
      ActivityModel(
        id: 'act-002',
        challengeId: 'challenge-gk-history',
        challengeTitle: 'Historical Turning Points',
        userId: AppConstants.demoUserId,
        type: ActivityType.quiz,
        status: ActivityStatus.completed,
        score: 80,
        accuracy: 80.0,
        pointsEarned: 80,
        timeTakenSeconds: 420,
        completedAt: now.subtract(const Duration(days: 1, hours: 2)),
        category: 'General Knowledge',
        difficulty: 'Intermediate',
      ),
      ActivityModel(
        id: 'act-003',
        challengeId: 'challenge-daily-code',
        challengeTitle: 'Code Duel: String & Array Mastery',
        userId: AppConstants.demoUserId,
        type: ActivityType.coding,
        status: ActivityStatus.completed,
        score: 100,
        accuracy: 100.0,
        pointsEarned: 150,
        timeTakenSeconds: 980,
        completedAt: now.subtract(const Duration(days: 2, hours: 5)),
        category: 'Programming',
        difficulty: 'Beginner',
      ),
    ];
  }

  void addActivity(ActivityModel activity) {
    state = [activity, ...state];
  }

  void clearActivities() {
    state = const [];
  }
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, List<ActivityModel>>((ref) {
      return ActivityNotifier();
    });

// ============================================================================
// QUIZ ATTEMPT NOTIFIER & FAMILY PROVIDER
// ============================================================================

class QuizAttemptNotifier extends StateNotifier<QuizAttemptModel?> {
  QuizAttemptNotifier(this._quizRepository, this.challengeId, this.userId)
    : super(null) {
    _initialize();
  }

  final QuizRepository _quizRepository;
  final String challengeId;
  final String userId;

  Future<void> _initialize() async {
    final attempt = await _quizRepository.createAttempt(challengeId, userId);
    state = attempt;
  }

  Future<void> selectAnswer(String questionId, int? selectedIndex) async {
    if (state == null) return;
    final updated = await _quizRepository.updateAnswer(
      state!.id,
      questionId,
      selectedIndex,
    );
    state = updated;
  }

  Future<void> toggleMarkForReview(String questionId) async {
    if (state == null) return;
    final updated = await _quizRepository.toggleMarkForReview(
      state!.id,
      questionId,
    );
    state = updated;
  }

  Future<QuizAttemptModel> submit() async {
    if (state == null) {
      throw Exception('No active quiz attempt to submit');
    }
    final submitted = await _quizRepository.submitAttempt(state!.id);
    state = submitted;
    return submitted;
  }
}

final currentAttemptProvider =
    StateNotifierProvider.family<
      QuizAttemptNotifier,
      QuizAttemptModel?,
      String
    >((ref, challengeId) {
      final quizRepo = ref.watch(quizRepositoryProvider);
      final user = ref.watch(authStateProvider).value;
      final userId = user?.id ?? AppConstants.demoUserId;
      return QuizAttemptNotifier(quizRepo, challengeId, userId);
    });

final userQuizAttemptsProvider =
    FutureProvider.family<List<QuizAttemptModel>, String>((ref, userId) {
      return ref.watch(quizRepositoryProvider).getAttemptsForUser(userId);
    });

// ============================================================================
// ONBOARDING
// ============================================================================

final onboardingCompleteProvider = StateProvider<bool>((ref) => false);
