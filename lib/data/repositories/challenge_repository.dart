import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../mock/mock_challenges.dart';
import '../mock/mock_questions.dart' as mock_q;
import '../models/challenge_model.dart';
import '../models/question_model.dart';

abstract class ChallengeRepository {
  Future<List<ChallengeModel>> getAllChallenges();
  Future<List<ChallengeModel>> getDailyChallenges();
  Future<ChallengeModel?> getChallengeById(String id);
  Future<List<ChallengeModel>> getChallengesByCategory(String category);
  Future<List<ChallengeModel>> getChallengesByDifficulty(String difficulty);
  Future<List<ChallengeModel>> searchChallenges(String query);
  Future<List<ChallengeModel>> getFilteredChallenges({
    String? category,
    String? difficulty,
    String? status,
    String? query,
    String? sortBy,
  });
  Future<void> markChallengeCompleted(
    String id, {
    required int score,
    required double accuracy,
    required int pointsEarned,
  });
  Future<List<QuestionModel>> getQuestionsForChallenge(String challengeId);
}

class MockChallengeRepository implements ChallengeRepository {
  MockChallengeRepository({SharedPreferences? preferences})
    : _prefs = preferences {
    _challenges = getMockChallenges();
  }

  SharedPreferences? _prefs;
  late List<ChallengeModel> _challenges;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<List<ChallengeModel>> getAllChallenges() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await _restoreDailyCompletions();
    return List<ChallengeModel>.unmodifiable(_challenges);
  }

  @override
  Future<List<ChallengeModel>> getDailyChallenges() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _restoreDailyCompletions();
    final dailyIds = {
      'challenge-daily-gk',
      'challenge-daily-tech',
      'challenge-daily-code',
    };

    final daily = _challenges.where((c) => dailyIds.contains(c.id)).toList();
    if (daily.isNotEmpty) {
      return daily;
    }
    return _challenges.take(3).toList();
  }

  @override
  Future<ChallengeModel?> getChallengeById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await _restoreDailyCompletions();
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ChallengeModel>> getChallengesByCategory(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return List<ChallengeModel>.unmodifiable(_challenges);
    }
    return _challenges.where((c) {
      return c.category.displayName.toLowerCase() == category.toLowerCase() ||
          c.category.name.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  @override
  Future<List<ChallengeModel>> getChallengesByDifficulty(
    String difficulty,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (difficulty.isEmpty || difficulty.toLowerCase() == 'all') {
      return List<ChallengeModel>.unmodifiable(_challenges);
    }
    return _challenges.where((c) {
      return c.difficulty.displayName.toLowerCase() ==
              difficulty.toLowerCase() ||
          c.difficulty.name.toLowerCase() == difficulty.toLowerCase();
    }).toList();
  }

  @override
  Future<List<ChallengeModel>> searchChallenges(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return List<ChallengeModel>.unmodifiable(_challenges);
    }
    return _challenges.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.category.displayName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<List<ChallengeModel>> getFilteredChallenges({
    String? category,
    String? difficulty,
    String? status,
    String? query,
    String? sortBy,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    var results = List<ChallengeModel>.from(_challenges);

    // Filter Category
    if (category != null &&
        category.isNotEmpty &&
        category.toLowerCase() != 'all') {
      results = results.where((c) {
        return c.category.displayName.toLowerCase() == category.toLowerCase() ||
            c.category.name.toLowerCase() == category.toLowerCase();
      }).toList();
    }

    // Filter Difficulty
    if (difficulty != null &&
        difficulty.isNotEmpty &&
        difficulty.toLowerCase() != 'all') {
      results = results.where((c) {
        return c.difficulty.displayName.toLowerCase() ==
                difficulty.toLowerCase() ||
            c.difficulty.name.toLowerCase() == difficulty.toLowerCase();
      }).toList();
    }

    // Filter Status
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      results = results.where((c) {
        return c.status.displayName.toLowerCase() == status.toLowerCase() ||
            c.status.name.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    // Filter Query
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((c) {
        return c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.category.displayName.toLowerCase().contains(q);
      }).toList();
    }

    // Sort By
    if (sortBy != null && sortBy.isNotEmpty) {
      switch (sortBy.toLowerCase()) {
        case 'points':
        case 'maxpoints':
          results.sort((a, b) => b.maxPoints.compareTo(a.maxPoints));
          break;
        case 'difficulty':
          results.sort(
            (a, b) => a.difficulty.index.compareTo(b.difficulty.index),
          );
          break;
        case 'time':
        case 'duration':
          results.sort(
            (a, b) => a.timeLimitSeconds.compareTo(b.timeLimitSeconds),
          );
          break;
        case 'title':
        case 'alphabetical':
          results.sort((a, b) => a.title.compareTo(b.title));
          break;
        case 'questions':
          results.sort((a, b) => b.questionCount.compareTo(a.questionCount));
          break;
        default:
          break;
      }
    }

    return results;
  }

  @override
  Future<void> markChallengeCompleted(
    String id, {
    required int score,
    required double accuracy,
    required int pointsEarned,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _challenges.indexWhere((c) => c.id == id);
    if (index != -1) {
      final prefs = await _getPrefs();
      final today = DateTime.now();
      final dayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final completedKey = '${AppConstants.keyCompletedChallenges}_$dayKey';
      final completedIds = prefs.getStringList(completedKey) ?? [];
      if (completedIds.contains(id)) {
        return;
      }

      final existing = _challenges[index];
      _challenges[index] = existing.copyWith(
        status: ChallengeStatus.completed,
        userScore: score,
        userAccuracy: accuracy,
        completedAt: DateTime.now(),
      );

      completedIds.add(id);
      await prefs.setStringList(completedKey, completedIds);
      final currentPoints = prefs.getInt(AppConstants.keyUserPoints) ?? 0;
      await prefs.setInt(
        AppConstants.keyUserPoints,
        currentPoints + pointsEarned,
      );
    }
  }

  @override
  Future<List<QuestionModel>> getQuestionsForChallenge(
    String challengeId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mock_q.getQuestionsForChallenge(challengeId);
  }

  Future<void> _restoreDailyCompletions() async {
    final prefs = await _getPrefs();
    final now = DateTime.now();
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final completedIds =
        prefs.getStringList('${AppConstants.keyCompletedChallenges}_$dayKey') ??
        [];

    for (var index = 0; index < _challenges.length; index++) {
      final challenge = _challenges[index];
      if (completedIds.contains(challenge.id) &&
          challenge.status != ChallengeStatus.completed) {
        _challenges[index] = challenge.copyWith(
          status: ChallengeStatus.completed,
        );
      }
    }
  }
}
