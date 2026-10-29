import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final String id;
  final String challengeId;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final int points;
  final double difficultyWeight;

  const QuestionModel({
    required this.id,
    required this.challengeId,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.points = 10,
    this.difficultyWeight = 1.0,
  });

  bool isCorrect(int selectedIndex) => selectedIndex == correctOptionIndex;

  String get correctAnswerText =>
      (correctOptionIndex >= 0 && correctOptionIndex < options.length)
      ? options[correctOptionIndex]
      : '';

  QuestionModel copyWith({
    String? id,
    String? challengeId,
    String? questionText,
    List<String>? options,
    int? correctOptionIndex,
    String? explanation,
    int? points,
    double? difficultyWeight,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      difficultyWeight: difficultyWeight ?? this.difficultyWeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'points': points,
      'difficultyWeight': difficultyWeight,
    };
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    final optionsList = rawOptions.map((e) => e.toString()).toList();

    // Ensure fallback to 4 options if not present
    final paddedOptions = optionsList.length == 4
        ? optionsList
        : [
            ...optionsList,
            ...List.generate(
              (4 - optionsList.length).clamp(0, 4),
              (index) => 'Option ${optionsList.length + index + 1}',
            ),
          ].take(4).toList();

    return QuestionModel(
      id: json['id'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      options: paddedOptions,
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 10,
      difficultyWeight: (json['difficultyWeight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    challengeId,
    questionText,
    options,
    correctOptionIndex,
    explanation,
    points,
    difficultyWeight,
  ];
}
