import '../../core/constants/app_colors.dart';
import '../models/achievement_model.dart';

abstract class AchievementRepository {
  Future<List<AchievementModel>> getAchievements(String userId);
  Future<List<AchievementModel>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> stats,
  );
  Future<int> getUnlockedCount(String userId);
}

class MockAchievementRepository implements AchievementRepository {
  MockAchievementRepository() {
    _initDefaultAchievements();
  }

  final List<AchievementModel> _achievements = [];

  void _initDefaultAchievements() {
    final now = DateTime.now();
    _achievements.addAll([
      AchievementModel(
        id: 'ach-first-duel',
        title: 'First Blood',
        description: 'Complete your very first DailyDuel challenge.',
        icon: 'emoji_events',
        category: AchievementCategory.challenge,
        isUnlocked: true,
        progress: 1,
        target: 1,
        unlockedAt: now.subtract(const Duration(days: 14)),
        points: 50,
        color: AppColors.successGreen,
      ),
      AchievementModel(
        id: 'ach-week-streak',
        title: 'Streak Pioneer',
        description: 'Maintain an unbroken 7-day challenge streak.',
        icon: 'local_fire_department',
        category: AchievementCategory.streak,
        isUnlocked: true,
        progress: 7,
        target: 7,
        unlockedAt: now.subtract(const Duration(days: 1)),
        points: 100,
        color: AppColors.mathematicsColor,
      ),
      AchievementModel(
        id: 'ach-perfect-score',
        title: 'Sharpshooter',
        description: 'Attain a flawless 100% score on any quiz duel.',
        icon: 'military_tech',
        category: AchievementCategory.accuracy,
        isUnlocked: true,
        progress: 1,
        target: 1,
        unlockedAt: now.subtract(const Duration(days: 6)),
        points: 100,
        color: AppColors.goldColor,
      ),
      AchievementModel(
        id: 'ach-trivia-titan',
        title: 'Trivia Titan',
        description: 'Successfully complete 25 challenge duels.',
        icon: 'psychology',
        category: AchievementCategory.challenge,
        isUnlocked: true,
        progress: 25,
        target: 25,
        unlockedAt: now.subtract(const Duration(days: 3)),
        points: 150,
        color: AppColors.primaryBlue,
      ),
      AchievementModel(
        id: 'ach-speed-demon',
        title: 'Speed Demon',
        description: 'Complete a 10-question challenge in under 3 minutes.',
        icon: 'bolt',
        category: AchievementCategory.special,
        isUnlocked: true,
        progress: 1,
        target: 1,
        unlockedAt: now.subtract(const Duration(days: 8)),
        points: 100,
        color: AppColors.secondaryViolet,
      ),
      AchievementModel(
        id: 'ach-code-gladiator',
        title: 'Code Gladiator',
        description: 'Successfully pass all test cases on a coding duel.',
        icon: 'code',
        category: AchievementCategory.special,
        isUnlocked: true,
        progress: 1,
        target: 1,
        unlockedAt: now.subtract(const Duration(days: 5)),
        points: 150,
        color: AppColors.devOpsColor,
      ),
      AchievementModel(
        id: 'ach-month-streak',
        title: 'Monthly Master',
        description: 'Reach a towering consecutive 30-day streak.',
        icon: 'whatshot',
        category: AchievementCategory.streak,
        isUnlocked: false,
        progress: 7,
        target: 30,
        points: 300,
        color: AppColors.mathematicsColor,
      ),
      AchievementModel(
        id: 'ach-century',
        title: 'Centennial Scholar',
        description: 'Complete 100 challenges across all categories.',
        icon: 'stars',
        category: AchievementCategory.challenge,
        isUnlocked: false,
        progress: 38,
        target: 100,
        points: 500,
        color: AppColors.goldColor,
      ),
      AchievementModel(
        id: 'ach-accuracy-legend',
        title: 'Accuracy Legend',
        description: 'Attain 90%+ accuracy in 20 distinct duels.',
        icon: 'verified',
        category: AchievementCategory.accuracy,
        isUnlocked: false,
        progress: 14,
        target: 20,
        points: 250,
        color: AppColors.successGreen,
      ),
      AchievementModel(
        id: 'ach-night-owl',
        title: 'Midnight Strategist',
        description: 'Complete a challenge between 11 PM and 4 AM.',
        icon: 'bedtime',
        category: AchievementCategory.special,
        isUnlocked: false,
        progress: 0,
        target: 1,
        points: 75,
        color: AppColors.cybersecurityColor,
      ),
    ]);
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<AchievementModel>.unmodifiable(_achievements);
  }

  @override
  Future<List<AchievementModel>> checkAndUnlockAchievements(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final newlyUnlocked = <AchievementModel>[];

    final streak = (stats['streak'] as num?)?.toInt() ?? 0;
    final challengesCompleted =
        (stats['challengesCompleted'] as num?)?.toInt() ?? 0;
    final averageAccuracy =
        (stats['averageAccuracy'] as num?)?.toDouble() ?? 0.0;

    for (var i = 0; i < _achievements.length; i++) {
      final ach = _achievements[i];
      if (ach.isUnlocked) continue;

      var shouldUnlock = false;
      var newProgress = ach.progress;

      if (ach.id == 'ach-month-streak') {
        newProgress = streak;
        if (streak >= 30) shouldUnlock = true;
      } else if (ach.id == 'ach-century') {
        newProgress = challengesCompleted;
        if (challengesCompleted >= 100) shouldUnlock = true;
      } else if (ach.id == 'ach-accuracy-legend') {
        if (averageAccuracy >= 90.0) {
          newProgress = (newProgress + 1).clamp(0, ach.target);
          if (newProgress >= ach.target) shouldUnlock = true;
        }
      }

      if (shouldUnlock) {
        final updated = ach.copyWith(
          isUnlocked: true,
          progress: ach.target,
          unlockedAt: DateTime.now(),
        );
        _achievements[i] = updated;
        newlyUnlocked.add(updated);
      } else if (newProgress != ach.progress) {
        _achievements[i] = ach.copyWith(progress: newProgress);
      }
    }

    return newlyUnlocked;
  }

  @override
  Future<int> getUnlockedCount(String userId) async {
    return _achievements.where((a) => a.isUnlocked).length;
  }
}
