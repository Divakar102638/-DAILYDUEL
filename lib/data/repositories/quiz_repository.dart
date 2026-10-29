import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../mock/mock_questions.dart' as mock_q;
import '../models/question_model.dart';
import '../models/quiz_attempt_model.dart';

abstract class QuizRepository {
  Future<QuizAttemptModel> createAttempt(String challengeId, String userId);
  Future<QuizAttemptModel?> getAttempt(String attemptId);
  Future<QuizAttemptModel> updateAnswer(
    String attemptId,
    String questionId,
    int? selectedIndex,
  );
  Future<QuizAttemptModel> toggleMarkForReview(
    String attemptId,
    String questionId,
  );
  Future<QuizAttemptModel> submitAttempt(String attemptId);
  Future<List<QuizAttemptModel>> getAttemptsForUser(String userId);
  QuizAttemptModel calculateScore(
    QuizAttemptModel attempt,
    List<QuestionModel> questions,
  );
}

class MockQuizRepository implements QuizRepository {
  MockQuizRepository({SharedPreferences? preferences}) : _prefs = preferences;

  SharedPreferences? _prefs;
  final Map<String, QuizAttemptModel> _attempts = {};
  final Uuid _uuid = const Uuid();

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<QuizAttemptModel> createAttempt(
    String challengeId,
    String userId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final attemptId = 'attempt-${_uuid.v4()}';
    final attempt = QuizAttemptModel(
      id: attemptId,
      challengeId: challengeId,
      userId: userId,
      startedAt: DateTime.now(),
      answers: const {},
      markedForReview: const [],
      isSubmitted: false,
      isCompleted: false,
    );

    _attempts[attemptId] = attempt;
    return attempt;
  }

  @override
  Future<QuizAttemptModel?> getAttempt(String attemptId) async {
    if (_attempts.containsKey(attemptId)) {
      return _attempts[attemptId];
    }

    final prefs = await _getPrefs();
    final savedAttempts =
        prefs.getStringList(AppConstants.keyCompletedAttempts) ?? [];
    for (final jsonStr in savedAttempts) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final attempt = QuizAttemptModel.fromJson(map);
        if (attempt.id == attemptId) {
          _attempts[attemptId] = attempt;
          return attempt;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<QuizAttemptModel> updateAnswer(
    String attemptId,
    String questionId,
    int? selectedIndex,
  ) async {
    final existing = await getAttempt(attemptId);
    if (existing == null) {
      throw Exception('Attempt not found: $attemptId');
    }

    if (existing.isSubmitted) {
      throw Exception('Cannot update answer on a submitted quiz attempt');
    }

    final updatedAnswers = Map<String, int?>.from(existing.answers);
    if (selectedIndex == null) {
      updatedAnswers.remove(questionId);
    } else {
      updatedAnswers[questionId] = selectedIndex;
    }

    final updated = existing.copyWith(answers: updatedAnswers);
    _attempts[attemptId] = updated;
    return updated;
  }

  @override
  Future<QuizAttemptModel> toggleMarkForReview(
    String attemptId,
    String questionId,
  ) async {
    final existing = await getAttempt(attemptId);
    if (existing == null) {
      throw Exception('Attempt not found: $attemptId');
    }

    final updatedMarked = List<String>.from(existing.markedForReview);
    if (updatedMarked.contains(questionId)) {
      updatedMarked.remove(questionId);
    } else {
      updatedMarked.add(questionId);
    }

    final updated = existing.copyWith(markedForReview: updatedMarked);
    _attempts[attemptId] = updated;
    return updated;
  }

  @override
  QuizAttemptModel calculateScore(
    QuizAttemptModel attempt,
    List<QuestionModel> questions,
  ) {
    var correct = 0;
    var incorrect = 0;
    var unanswered = 0;

    for (final q in questions) {
      final selected = attempt.answers[q.id];
      if (selected == null) {
        unanswered++;
      } else if (q.isCorrect(selected)) {
        correct++;
      } else {
        incorrect++;
      }
    }

    final total = questions.length;
    final accuracy = total > 0 ? (correct / total) * 100.0 : 0.0;
    final points = questions.fold<int>(0, (total, question) {
      return attempt.answers[question.id] != null &&
              question.isCorrect(attempt.answers[question.id]!)
          ? total + question.points
          : total;
    });

    // Perfect score bonus
    if (total > 0 && correct == total) {
      return attempt.copyWith(
        correctCount: correct,
        incorrectCount: incorrect,
        unansweredCount: unanswered,
        accuracy: accuracy,
        pointsEarned: points + AppConstants.bonusPointsPerfectScore,
        score: points + AppConstants.bonusPointsPerfectScore,
      );
    }

    return attempt.copyWith(
      correctCount: correct,
      incorrectCount: incorrect,
      unansweredCount: unanswered,
      accuracy: accuracy,
      pointsEarned: points,
      score: points,
    );
  }

  @override
  Future<QuizAttemptModel> submitAttempt(String attemptId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final existing = await getAttempt(attemptId);
    if (existing == null) {
      throw Exception('Attempt not found: $attemptId');
    }

    if (existing.isSubmitted) {
      return existing;
    }

    final questions = mock_q.getQuestionsForChallenge(existing.challengeId);
    final scored = calculateScore(existing, questions);
    final now = DateTime.now();
    final timeTaken = now.difference(scored.startedAt).inSeconds;

    final completedAttempt = scored.copyWith(
      submittedAt: now,
      timeTakenSeconds: timeTaken > 0 ? timeTaken : 1,
      isSubmitted: true,
      isCompleted: true,
    );

    _attempts[attemptId] = completedAttempt;

    // Persist to SharedPreferences
    final prefs = await _getPrefs();
    final savedList =
        prefs.getStringList(AppConstants.keyCompletedAttempts) ?? [];
    savedList.add(jsonEncode(completedAttempt.toJson()));
    await prefs.setStringList(AppConstants.keyCompletedAttempts, savedList);

    return completedAttempt;
  }

  @override
  Future<List<QuizAttemptModel>> getAttemptsForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final userAttempts = _attempts.values
        .where((a) => a.userId == userId && a.isSubmitted)
        .toList();

    final prefs = await _getPrefs();
    final saved = prefs.getStringList(AppConstants.keyCompletedAttempts) ?? [];

    for (final jsonStr in saved) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final attempt = QuizAttemptModel.fromJson(map);
        if (attempt.userId == userId &&
            !userAttempts.any((a) => a.id == attempt.id)) {
          userAttempts.add(attempt);
        }
      } catch (_) {}
    }

    userAttempts.sort((a, b) {
      final aDate = a.submittedAt ?? a.startedAt;
      final bDate = b.submittedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });

    return userAttempts;
  }
}
