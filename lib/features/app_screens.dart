import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_strings.dart';
import '../data/models/activity_model.dart';
import '../data/models/challenge_model.dart';
import '../data/models/leaderboard_entry_model.dart';
import '../data/models/question_model.dart';
import '../data/models/quiz_attempt_model.dart';
import '../data/models/settings_model.dart';
import '../data/models/user_model.dart';
import '../core/routing/app_router.dart';
import 'providers/providers.dart';

class ChallengeCatalogScreen extends ConsumerStatefulWidget {
  const ChallengeCatalogScreen({super.key});

  @override
  ConsumerState<ChallengeCatalogScreen> createState() =>
      _ChallengeCatalogScreenState();
}

class _ChallengeCatalogScreenState
    extends ConsumerState<ChallengeCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _category = 'All';
  String _difficulty = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ref.watch(allChallengesProvider);
    return _PageScaffold(
      title: AppStrings.challenges,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: AppStrings.searchChallenges,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.challengeCategories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: AppConstants.difficultyLevels
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _difficulty = value ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: challenges.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorPanel(
                message: 'Challenges could not be loaded: $error',
                onRetry: () => ref.invalidate(allChallengesProvider),
              ),
              data: (items) {
                final query = _searchController.text.trim().toLowerCase();
                final visible = items.where((challenge) {
                  final matchesQuery =
                      query.isEmpty ||
                      challenge.title.toLowerCase().contains(query) ||
                      challenge.description.toLowerCase().contains(query);
                  final matchesCategory =
                      _category == 'All' ||
                      challenge.category.displayName == _category;
                  final matchesDifficulty =
                      _difficulty == 'All' ||
                      challenge.difficulty.displayName == _difficulty;
                  return matchesQuery && matchesCategory && matchesDifficulty;
                }).toList();
                if (visible.isEmpty) {
                  return const Center(child: Text('No matching challenges.'));
                }
                return ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final challenge = visible[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          challenge.type == ChallengeType.coding
                              ? Icons.code
                              : Icons.quiz_outlined,
                        ),
                        title: Text(challenge.title),
                        subtitle: Text(
                          '${challenge.category.displayName} · '
                          '${challenge.difficulty.displayName} · '
                          '${challenge.timeLimitSeconds ~/ 60} min',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRoutes.quizInstructionsPath(challenge.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeInstructionsScreen extends ConsumerWidget {
  const ChallengeInstructionsScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeFuture = ref
        .watch(challengeRepositoryProvider)
        .getChallengeById(challengeId);
    return _PageScaffold(
      title: 'Challenge details',
      child: FutureBuilder<ChallengeModel?>(
        future: challengeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(
              message: 'Could not load challenge: ${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return _ErrorPanel(
                message:
                    'Could not load the coding challenge: ${snapshot.error}',
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final challenge = snapshot.data;
          if (challenge == null) {
            return const Center(child: Text('Challenge not found.'));
          }
          return ListView(
            children: [
              Text(
                challenge.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(challenge.description),
              const SizedBox(height: 20),
              _DetailRow(
                label: 'Category',
                value: challenge.category.displayName,
              ),
              _DetailRow(
                label: 'Difficulty',
                value: challenge.difficulty.displayName,
              ),
              _DetailRow(
                label: 'Questions',
                value: challenge.questionCount.toString(),
              ),
              _DetailRow(
                label: 'Time limit',
                value: '${challenge.timeLimitSeconds ~/ 60} minutes',
              ),
              _DetailRow(
                label: 'Maximum points',
                value: '${challenge.maxPoints}',
              ),
              if (challenge.type == ChallengeType.coding) ...[
                const SizedBox(height: 12),
                const _InfoBanner(
                  text:
                      'Code evaluation is simulated locally. No code is run '
                      'and results are not sent to a server.',
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    challenge.status == ChallengeStatus.locked ||
                        challenge.status == ChallengeStatus.upcoming
                    ? null
                    : () => context.push(
                        challenge.type == ChallengeType.coding
                            ? AppRoutes.codingChallengePath(challenge.id)
                            : AppRoutes.quizPath(challenge.id),
                      ),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  challenge.type == ChallengeType.coding
                      ? AppStrings.solveChallenge
                      : AppStrings.startChallenge,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class QuizSessionScreen extends ConsumerStatefulWidget {
  const QuizSessionScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  ChallengeModel? _challenge;
  List<QuestionModel> _questions = const [];
  final Map<String, int?> _answers = {};
  final Set<String> _markedForReview = {};
  int _currentIndex = 0;
  int _secondsRemaining = 0;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Timer? _timer;
  String? _attemptId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final challenge = await ref
          .read(challengeRepositoryProvider)
          .getChallengeById(widget.challengeId);
      if (challenge == null) {
        throw StateError('Challenge not found: ${widget.challengeId}');
      }
      final questions = await ref
          .read(challengeRepositoryProvider)
          .getQuestionsForChallenge(widget.challengeId);
      if (questions.isEmpty) {
        throw StateError(
          'No quiz questions are configured for this challenge.',
        );
      }
      final userId =
          ref.read(authStateProvider).value?.id ?? AppConstants.demoUserId;
      final attempt = await ref
          .read(quizRepositoryProvider)
          .createAttempt(widget.challengeId, userId);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _questions = questions;
        _secondsRemaining = challenge.timeLimitSeconds;
        _attemptId = attempt.id;
        _userId = userId;
        _loading = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _submitting) return;
        if (_secondsRemaining <= 1) {
          setState(() => _secondsRemaining = 0);
          _submit();
        } else {
          setState(() => _secondsRemaining--);
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectAnswer(QuestionModel question, int? selected) async {
    final attemptId = _attemptId;
    if (attemptId == null || _submitting) return;
    setState(() => _answers[question.id] = selected);
    try {
      await ref
          .read(quizRepositoryProvider)
          .updateAnswer(attemptId, question.id, selected);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save your answer: $error')),
        );
      }
    }
  }

  Future<void> _toggleReview(String questionId) async {
    final attemptId = _attemptId;
    if (attemptId == null || _submitting) return;
    try {
      await ref
          .read(quizRepositoryProvider)
          .toggleMarkForReview(attemptId, questionId);
      if (mounted) {
        setState(() {
          if (!_markedForReview.add(questionId)) {
            _markedForReview.remove(questionId);
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark question: $error')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final attemptId = _attemptId;
    final challenge = _challenge;
    if (attemptId == null || challenge == null || _submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    try {
      final quizRepository = ref.read(quizRepositoryProvider);
      final existingAttempt = await quizRepository.getAttempt(attemptId);
      final attempt = await quizRepository.submitAttempt(attemptId);
      if (existingAttempt?.isSubmitted != true) {
        final user = ref.read(authStateProvider).value;
        if (user != null) {
          final completedCount = user.challengesCompleted;
          final updatedUser = user.copyWith(
            points: user.points + attempt.pointsEarned,
            challengesCompleted: completedCount + 1,
            averageAccuracy: completedCount == 0
                ? attempt.accuracy
                : ((user.averageAccuracy * completedCount + attempt.accuracy) /
                      (completedCount + 1)),
          );
          await ref
              .read(authStateProvider.notifier)
              .updateCurrentUser(updatedUser);
        }
      }
      await ref
          .read(challengeRepositoryProvider)
          .markChallengeCompleted(
            challenge.id,
            score: attempt.score,
            accuracy: attempt.accuracy,
            pointsEarned: attempt.pointsEarned,
          );
      ref.invalidate(
        userQuizAttemptsProvider(_userId ?? AppConstants.demoUserId),
      );
      if (mounted) context.go(AppRoutes.quizResultsPath(attempt.id));
    } catch (error) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit the quiz: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: _ErrorPanel(message: _error!),
      );
    }
    final question = _questions[_currentIndex];
    final answeredCount = _answers.values
        .where((value) => value != null)
        .length;
    final time = Duration(seconds: _secondsRemaining);
    return Scaffold(
      appBar: AppBar(
        title: Text(_challenge?.title ?? 'Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${time.inMinutes.toString().padLeft(2, '0')}:'
                '${time.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                key: const ValueKey('quiz-countdown'),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
              ),
              const SizedBox(height: 12),
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length} · '
                '$answeredCount answered',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _toggleReview(question.id),
                  icon: Icon(
                    _markedForReview.contains(question.id)
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  label: Text(
                    _markedForReview.contains(question.id)
                        ? 'Marked for review'
                        : 'Mark for review',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                question.questionText,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RadioGroup<int>(
                  groupValue: _answers[question.id],
                  onChanged: (value) => _selectAnswer(question, value),
                  child: ListView.builder(
                    itemCount: question.options.length,
                    itemBuilder: (context, index) => Card(
                      child: RadioListTile<int>(
                        value: index,
                        title: Text(question.options[index]),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _currentIndex == 0
                        ? null
                        : () => setState(() => _currentIndex--),
                    child: const Text('Previous'),
                  ),
                  const Spacer(),
                  if (_currentIndex < _questions.length - 1)
                    FilledButton(
                      onPressed: () => setState(() => _currentIndex++),
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Submitting…' : 'Submit quiz'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    super.key,
    required this.attemptId,
    this.reviewOnly = false,
  });

  final String attemptId;
  final bool reviewOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(quizRepositoryProvider).getAttempt(attemptId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz result')),
            body: _ErrorPanel(
              message: 'Could not load this attempt: ${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final attempt = snapshot.data;
        if (attempt == null) {
          return const Scaffold(
            body: Center(child: Text('Quiz attempt not found.')),
          );
        }
        return FutureBuilder<List<QuestionModel>>(
          future: ref
              .read(challengeRepositoryProvider)
              .getQuestionsForChallenge(attempt.challengeId),
          builder: (context, questionsSnapshot) {
            if (questionsSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Quiz result')),
                body: _ErrorPanel(
                  message:
                      'Could not load answer details: '
                      '${questionsSnapshot.error}',
                ),
              );
            }
            if (!questionsSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final questions = questionsSnapshot.data!;
            if (reviewOnly) {
              return _AnswerReviewPage(questions: questions, attempt: attempt);
            }
            return _PageScaffold(
              title: 'Quiz results',
              child: ListView(
                children: [
                  Text(
                    'Challenge complete',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Score', value: '${attempt.score}'),
                  _DetailRow(
                    label: 'Correct answers',
                    value: '${attempt.correctCount}',
                  ),
                  _DetailRow(
                    label: 'Incorrect answers',
                    value: '${attempt.incorrectCount}',
                  ),
                  _DetailRow(
                    label: 'Unanswered',
                    value: '${attempt.unansweredCount}',
                  ),
                  _DetailRow(
                    label: 'Accuracy',
                    value: '${attempt.accuracy.toStringAsFixed(0)}%',
                  ),
                  _DetailRow(
                    label: 'Points earned',
                    value: '${attempt.pointsEarned}',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () =>
                        context.push(AppRoutes.answerReviewPath(attempt.id)),
                    child: const Text('Review answers'),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Back to home'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AnswerReviewPage extends StatelessWidget {
  const _AnswerReviewPage({required this.questions, required this.attempt});

  final List<QuestionModel> questions;
  final QuizAttemptModel attempt;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Answer review',
      child: ListView.separated(
        itemCount: questions.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final question = questions[index];
          final answer = attempt.answers[question.id];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. ${question.questionText}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Your answer: '
                '${answer == null ? 'Not answered' : question.options[answer]}',
              ),
              Text('Correct answer: ${question.correctAnswerText}'),
              if (question.explanation.isNotEmpty)
                Text('Why: ${question.explanation}'),
            ],
          );
        },
      ),
    );
  }
}

class CodingChallengeScreen extends ConsumerStatefulWidget {
  const CodingChallengeScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  ConsumerState<CodingChallengeScreen> createState() =>
      _CodingChallengeScreenState();
}

class _CodingChallengeScreenState extends ConsumerState<CodingChallengeScreen> {
  final TextEditingController _codeController = TextEditingController(
    text: '// Write your solution here\n',
  );
  String _language = 'Dart';
  String? _result;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Coding challenge',
      child: FutureBuilder<ChallengeModel?>(
        future: ref
            .read(challengeRepositoryProvider)
            .getChallengeById(widget.challengeId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final challenge = snapshot.data;
          if (challenge == null) {
            return const Center(child: Text('Challenge not found.'));
          }
          return ListView(
            children: [
              Text(
                challenge.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(challenge.description),
              const SizedBox(height: 8),
              const _InfoBanner(
                text:
                    'Demo only: code is not compiled or executed. The '
                    'submission response is simulated on this device.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: const InputDecoration(labelText: 'Language'),
                items: const ['Dart', 'Python', 'JavaScript']
                    .map(
                      (language) => DropdownMenuItem(
                        value: language,
                        child: Text(language),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _language = value ?? _language),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                minLines: 12,
                maxLines: 18,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Solution',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _result = _codeController.text.trim().length > 24
                      ? 'Simulated submission received for $_language. No test '
                            'cases were run.'
                      : 'Add a longer solution before submitting. No code was run.';
                }),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Submit demo solution'),
              ),
              if (_result != null) ...[
                const SizedBox(height: 12),
                _InfoBanner(text: _result!),
              ],
            ],
          );
        },
      ),
    );
  }
}

enum AppFeature {
  leaderboard,
  activity,
  profile,
  achievements,
  notifications,
  settings,
  editProfile,
  admin,
  createQuiz,
  editQuiz,
  manageUsers,
}

class AppFeatureScreen extends ConsumerWidget {
  const AppFeatureScreen({super.key, required this.feature, this.itemId});

  final AppFeature feature;
  final String? itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (feature) {
      AppFeature.leaderboard => const _LeaderboardPage(),
      AppFeature.activity => const _ActivityPage(),
      AppFeature.profile => const _ProfilePage(),
      AppFeature.achievements => const _AchievementsPage(),
      AppFeature.notifications => const _NotificationsPage(),
      AppFeature.settings => const _SettingsPage(),
      AppFeature.editProfile => const _EditProfilePage(),
      AppFeature.admin => const _AdminPage(),
      AppFeature.createQuiz => const _AdminQuizFormPage(),
      AppFeature.editQuiz => _AdminQuizFormPage(quizId: itemId),
      AppFeature.manageUsers => const _ManageUsersPage(),
    };
  }
}

class _LeaderboardPage extends ConsumerStatefulWidget {
  const _LeaderboardPage();

  @override
  ConsumerState<_LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<_LeaderboardPage> {
  String _period = 'Global';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final leaderboard = switch (_period) {
      'Weekly' => ref.watch(weeklyLeaderboardProvider),
      'Daily' => ref.watch(dailyLeaderboardProvider),
      'Friends' => ref.watch(friendsLeaderboardProvider),
      _ => ref.watch(globalLeaderboardProvider),
    };
    return _PageScaffold(
      title: AppStrings.leaderboard,
      child: Column(
        children: [
          const _InfoBanner(
            text:
                'Demonstration rankings use local mock data and are not '
                'synchronized with other users.',
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _period,
            decoration: const InputDecoration(labelText: 'Leaderboard'),
            items: const ['Global', 'Weekly', 'Daily', 'Friends']
                .map(
                  (period) =>
                      DropdownMenuItem(value: period, child: Text(period)),
                )
                .toList(),
            onChanged: (value) => setState(() => _period = value ?? 'Global'),
          ),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search users',
            ),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
          ),
          Expanded(
            child: leaderboard.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorPanel(message: '$error'),
              data: (entries) {
                final filtered = entries
                    .where(
                      (entry) =>
                          entry.fullName.toLowerCase().contains(_query) ||
                          entry.username.toLowerCase().contains(_query),
                    )
                    .toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _LeaderboardTile(entry: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});

  final LeaderboardEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${entry.rank}')),
      title: Text(entry.fullName),
      subtitle: Text('@${entry.username} · ${entry.completedChallenges} duels'),
      trailing: Text('${entry.points} pts'),
    );
  }
}

class _ActivityPage extends ConsumerWidget {
  const _ActivityPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activityProvider);
    final userId =
        ref.watch(authStateProvider).value?.id ?? AppConstants.demoUserId;
    final attempts = ref.watch(userQuizAttemptsProvider(userId));
    return _PageScaffold(
      title: AppStrings.activity,
      child: ListView(
        children: [
          ...activities.map((activity) => _ActivityTile(activity: activity)),
          attempts.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _ErrorPanel(
              message: 'Quiz history could not be loaded: $error',
            ),
            data: (items) => Column(
              children: items
                  .map((attempt) => _QuizAttemptTile(attempt: attempt))
                  .toList(),
            ),
          ),
          if (activities.isEmpty)
            attempts.maybeWhen(
              data: (items) => items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No activity yet. Complete a challenge to see it here.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _QuizAttemptTile extends ConsumerWidget {
  const _QuizAttemptTile({required this.attempt});

  final QuizAttemptModel attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ChallengeModel?>(
      future: ref
          .read(challengeRepositoryProvider)
          .getChallengeById(attempt.challengeId),
      builder: (context, snapshot) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(snapshot.data?.title ?? 'Quiz challenge'),
            subtitle: Text(
              '${attempt.submittedAt?.toLocal() ?? attempt.startedAt.toLocal()} · '
              '${attempt.accuracy.toStringAsFixed(0)}% accuracy',
            ),
            trailing: Text('${attempt.pointsEarned} pts'),
            onTap: () => context.push(AppRoutes.quizResultsPath(attempt.id)),
          ),
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final ActivityModel activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          activity.type == ActivityType.coding
              ? Icons.code
              : Icons.quiz_outlined,
        ),
        title: Text(activity.challengeTitle),
        subtitle: Text(
          '${activity.completedAt.toLocal()} · '
          '${activity.accuracy.toStringAsFixed(0)}% accuracy',
        ),
        trailing: Text('${activity.pointsEarned} pts'),
      ),
    );
  }
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);
    return _PageScaffold(
      title: AppStrings.profile,
      child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorPanel(message: '$error'),
        data: (user) {
          final profile = user;
          if (profile == null) {
            return const Center(child: Text('Sign in to view your profile.'));
          }
          return ListView(
            children: [
              CircleAvatar(
                radius: 36,
                child: Text(
                  profile.avatarInitials,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                profile.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Center(child: Text('@${profile.username}')),
              if (profile.isDemo)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: _InfoBanner(
                    text: 'Demo profile. Profile details are stored locally.',
                  ),
                ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Points', value: '${profile.points}'),
              _DetailRow(label: 'Global rank', value: '#${profile.rank}'),
              _DetailRow(label: 'Streak', value: '${profile.streak} days'),
              _DetailRow(
                label: 'Challenges completed',
                value: '${profile.challengesCompleted}',
              ),
              _DetailRow(
                label: 'Average accuracy',
                value: '${profile.averageAccuracy.toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                child: const Text('Edit profile'),
              ),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.achievements),
                child: const Text('Achievements'),
              ),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.settings),
                child: const Text('Settings'),
              ),
              if (profile.role == UserRole.admin)
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.admin),
                  child: const Text('Admin demonstration'),
                ),
              TextButton(
                onPressed: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                child: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AchievementsPage extends ConsumerWidget {
  const _AchievementsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    return _PageScaffold(
      title: AppStrings.achievements,
      child: achievements.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorPanel(message: '$error'),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  item.isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: item.isUnlocked ? Colors.amber : null,
                ),
                title: Text(item.title),
                subtitle: Text(item.description),
                trailing: Text(
                  item.isUnlocked
                      ? 'Unlocked'
                      : '${item.progress}/${item.target}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsPage extends ConsumerWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return _PageScaffold(
      title: AppStrings.notifications,
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(notificationsProvider.notifier).markAllAsRead(),
          child: const Text('Mark all read'),
        ),
      ],
      child: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorPanel(message: '$error'),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final notification = items[index];
            return ListTile(
              leading: Icon(
                notification.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
              ),
              title: Text(notification.title),
              subtitle: Text(notification.body),
              onTap: () => ref
                  .read(notificationsProvider.notifier)
                  .markAsRead(notification.id),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsPage extends ConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return _PageScaffold(
      title: AppStrings.settings,
      child: ListView(
        children: [
          DropdownButtonFormField<AppThemeMode>(
            initialValue: settings.themeMode,
            decoration: const InputDecoration(labelText: 'Theme'),
            items: AppThemeMode.values
                .map(
                  (mode) => DropdownMenuItem(
                    value: mode,
                    child: Text(mode.displayName),
                  ),
                )
                .toList(),
            onChanged: (mode) {
              if (mode != null) notifier.setThemeMode(mode);
            },
          ),
          SwitchListTile(
            title: const Text('Notifications'),
            value: settings.notificationsEnabled,
            onChanged: notifier.setNotificationsEnabled,
          ),
          SwitchListTile(
            title: const Text('Daily challenge reminder'),
            value: settings.dailyChallengeReminder,
            onChanged: notifier.setDailyChallengeReminder,
          ),
          SwitchListTile(
            title: const Text('Achievement alerts'),
            value: settings.achievementAlerts,
            onChanged: notifier.setAchievementAlerts,
          ),
          SwitchListTile(
            title: const Text('Leaderboard updates'),
            value: settings.leaderboardUpdates,
            onChanged: notifier.setLeaderboardUpdates,
          ),
          SwitchListTile(
            title: const Text('Sound effects'),
            value: settings.soundEffects,
            onChanged: notifier.setSoundEffects,
          ),
          SwitchListTile(
            title: const Text('Haptic feedback'),
            value: settings.hapticFeedback,
            onChanged: notifier.setHapticFeedback,
          ),
          const _InfoBanner(text: 'Settings are saved locally on this device.'),
        ],
      ),
    );
  }
}

class _EditProfilePage extends ConsumerStatefulWidget {
  const _EditProfilePage();

  @override
  ConsumerState<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<_EditProfilePage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const _PageScaffold(
        title: 'Edit profile',
        child: Center(child: Text('Sign in to edit your profile.')),
      );
    }
    if (!_initialized) {
      _nameController.text = user.fullName;
      _usernameController.text = user.username;
      _initialized = true;
    }
    return _PageScaffold(
      title: 'Edit profile',
      child: ListView(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_nameController.text.trim().isEmpty ||
                        _usernameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name and username are required.'),
                        ),
                      );
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      final updated = await ref
                          .read(profileRepositoryProvider)
                          .updateProfile(
                            userId: user.id,
                            fullName: _nameController.text,
                            username: _usernameController.text,
                          );
                      await ref
                          .read(authStateProvider.notifier)
                          .updateCurrentUser(updated);
                      if (!context.mounted) return;
                      context.pop();
                    } catch (error) {
                      if (!context.mounted) return;
                      setState(() => _saving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not save profile: $error'),
                        ),
                      );
                    }
                  },
            child: Text(_saving ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

class _AdminPage extends StatelessWidget {
  const _AdminPage();

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: AppStrings.adminPanel,
      child: ListView(
        children: [
          const _InfoBanner(
            text:
                'Admin tools are a local demonstration only. Changes are '
                'not published to a backend or shared with other users.',
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Create quiz'),
            onTap: () => context.push(AppRoutes.createQuiz),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Manage users'),
            onTap: () => context.push(AppRoutes.manageUsers),
          ),
        ],
      ),
    );
  }
}

class _AdminQuizFormPage extends StatefulWidget {
  const _AdminQuizFormPage({this.quizId});

  final String? quizId;

  @override
  State<_AdminQuizFormPage> createState() => _AdminQuizFormPageState();
}

class _AdminQuizFormPageState extends State<_AdminQuizFormPage> {
  final _titleController = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: widget.quizId == null ? 'Create quiz' : 'Edit quiz',
      child: ListView(
        children: [
          const _InfoBanner(
            text:
                'Demo form only. Quiz definitions are not persisted or '
                'published to a server.',
          ),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Quiz title'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a quiz title first.')),
                );
                return;
              }
              setState(() => _saved = true);
            },
            child: const Text('Save demo draft'),
          ),
          if (_saved)
            const _InfoBanner(
              text: 'Demo draft saved for this screen session.',
            ),
        ],
      ),
    );
  }
}

class _ManageUsersPage extends ConsumerWidget {
  const _ManageUsersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(globalLeaderboardProvider);
    return _PageScaffold(
      title: 'Manage users',
      child: Column(
        children: [
          const _InfoBanner(
            text:
                'Read-only mock users. Admin changes are not persisted or '
                'shared.',
          ),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorPanel(message: '$error'),
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final user = items[index];
                  return ListTile(
                    title: Text(user.fullName),
                    subtitle: Text('@${user.username}'),
                    trailing: Text('#${user.rank}'),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
