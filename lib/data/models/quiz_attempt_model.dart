import 'package:equatable/equatable.dart';

class QuizAttemptModel extends Equatable {
  final String id;
  final String challengeId;
  final String userId;
  final Map<String, int?>
  answers; // questionId -> selectedOptionIndex (null if unanswered)
  final List<String> markedForReview; // questionIds
  final DateTime startedAt;
  final DateTime? submittedAt;
  final int score;
  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;
  final double
  accuracy; // percentage 0.0 - 100.0 or 0.0 - 1.0 (let's provide percentage 0-100)
  final int pointsEarned;
  final int timeTakenSeconds;
  final bool isSubmitted;
  final bool isCompleted;

  const QuizAttemptModel({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.answers = const {},
    this.markedForReview = const [],
    required this.startedAt,
    this.submittedAt,
    this.score = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.unansweredCount = 0,
    this.accuracy = 0.0,
    this.pointsEarned = 0,
    this.timeTakenSeconds = 0,
    this.isSubmitted = false,
    this.isCompleted = false,
  });

  bool isQuestionAnswered(String questionId) => answers[questionId] != null;
  int? getSelectedAnswer(String questionId) => answers[questionId];
  bool isQuestionMarked(String questionId) =>
      markedForReview.contains(questionId);

  int get totalQuestions => correctCount + incorrectCount + unansweredCount;

  QuizAttemptModel copyWith({
    String? id,
    String? challengeId,
    String? userId,
    Map<String, int?>? answers,
    List<String>? markedForReview,
    DateTime? startedAt,
    DateTime? submittedAt,
    int? score,
    int? correctCount,
    int? incorrectCount,
    int? unansweredCount,
    double? accuracy,
    int? pointsEarned,
    int? timeTakenSeconds,
    bool? isSubmitted,
    bool? isCompleted,
  }) {
    return QuizAttemptModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      userId: userId ?? this.userId,
      answers: answers ?? this.answers,
      markedForReview: markedForReview ?? this.markedForReview,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      unansweredCount: unansweredCount ?? this.unansweredCount,
      accuracy: accuracy ?? this.accuracy,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'userId': userId,
      'answers': answers,
      'markedForReview': markedForReview,
      'startedAt': startedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'score': score,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'unansweredCount': unansweredCount,
      'accuracy': accuracy,
      'pointsEarned': pointsEarned,
      'timeTakenSeconds': timeTakenSeconds,
      'isSubmitted': isSubmitted,
      'isCompleted': isCompleted,
    };
  }

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? {};
    final answersMap = rawAnswers.map(
      (key, value) =>
          MapEntry(key, value != null ? (value as num).toInt() : null),
    );

    final rawMarked = json['markedForReview'] as List<dynamic>? ?? [];
    final markedList = rawMarked.map((e) => e.toString()).toList();

    return QuizAttemptModel(
      id: json['id'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      answers: answersMap,
      markedForReview: markedList,
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      score: (json['score'] as num?)?.toInt() ?? 0,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (json['incorrectCount'] as num?)?.toInt() ?? 0,
      unansweredCount: (json['unansweredCount'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      isSubmitted: json['isSubmitted'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    challengeId,
    userId,
    answers,
    markedForReview,
    startedAt,
    submittedAt,
    score,
    correctCount,
    incorrectCount,
    unansweredCount,
    accuracy,
    pointsEarned,
    timeTakenSeconds,
    isSubmitted,
    isCompleted,
  ];
}
