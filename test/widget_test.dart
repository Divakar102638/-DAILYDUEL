import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daily_duel/app.dart';
import 'package:daily_duel/data/mock/mock_questions.dart';
import 'package:daily_duel/data/models/quiz_attempt_model.dart';
import 'package:daily_duel/data/repositories/challenge_repository.dart';
import 'package:daily_duel/data/repositories/quiz_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('application starts on the branded splash screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: DailyDuelApp()));
    await tester.pump();

    expect(find.text('DailyDuel'), findsOneWidget);
    expect(find.text('Challenge Yourself. Rise Every Day.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Learn Every Day'), findsOneWidget);
  });

  test('quiz scoring respects question points and the perfect-score bonus', () {
    final questions = mockGkQuestions.take(2).toList();
    final attempt = QuizAttemptModel(
      id: 'attempt-test',
      challengeId: 'challenge-daily-gk',
      userId: 'user-test',
      startedAt: DateTime(2026),
      answers: {
        questions[0].id: questions[0].correctOptionIndex,
        questions[1].id: questions[1].correctOptionIndex,
      },
    );

    final result = MockQuizRepository().calculateScore(attempt, questions);

    expect(result.correctCount, 2);
    expect(result.incorrectCount, 0);
    expect(result.unansweredCount, 0);
    expect(result.accuracy, 100);
    expect(result.pointsEarned, 70);
  });

  test('quiz scoring counts incorrect and unanswered questions accurately', () {
    final questions = mockGkQuestions.take(3).toList();
    final attempt = QuizAttemptModel(
      id: 'attempt-test',
      challengeId: 'challenge-daily-gk',
      userId: 'user-test',
      startedAt: DateTime(2026),
      answers: {questions[0].id: (questions[0].correctOptionIndex + 1) % 4},
    );

    final result = MockQuizRepository().calculateScore(attempt, questions);

    expect(result.correctCount, 0);
    expect(result.incorrectCount, 1);
    expect(result.unansweredCount, 2);
    expect(result.accuracy, 0);
    expect(result.pointsEarned, 0);
  });

  test(
    'challenge completion does not award points twice on the same day',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = MockChallengeRepository(preferences: preferences);

      await repository.markChallengeCompleted(
        'challenge-daily-gk',
        score: 100,
        accuracy: 100,
        pointsEarned: 150,
      );
      await repository.markChallengeCompleted(
        'challenge-daily-gk',
        score: 100,
        accuracy: 100,
        pointsEarned: 150,
      );

      expect(preferences.getInt('user_points'), 150);
    },
  );
}
