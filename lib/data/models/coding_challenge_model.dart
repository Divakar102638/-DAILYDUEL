import 'package:equatable/equatable.dart';

class CodeExample extends Equatable {
  final String input;
  final String output;
  final String? explanation;

  const CodeExample({
    required this.input,
    required this.output,
    this.explanation,
  });

  CodeExample copyWith({String? input, String? output, String? explanation}) {
    return CodeExample(
      input: input ?? this.input,
      output: output ?? this.output,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {'input': input, 'output': output, 'explanation': explanation};
  }

  factory CodeExample.fromJson(Map<String, dynamic> json) {
    return CodeExample(
      input: json['input'] as String? ?? '',
      output: json['output'] as String? ?? '',
      explanation: json['explanation'] as String?,
    );
  }

  @override
  List<Object?> get props => [input, output, explanation];
}

class TestCase extends Equatable {
  final String input;
  final String expectedOutput;
  final bool isHidden;

  const TestCase({
    required this.input,
    required this.expectedOutput,
    this.isHidden = false,
  });

  TestCase copyWith({String? input, String? expectedOutput, bool? isHidden}) {
    return TestCase(
      input: input ?? this.input,
      expectedOutput: expectedOutput ?? this.expectedOutput,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'input': input,
      'expectedOutput': expectedOutput,
      'isHidden': isHidden,
    };
  }

  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      input: json['input'] as String? ?? '',
      expectedOutput: json['expectedOutput'] as String? ?? '',
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [input, expectedOutput, isHidden];
}

class CodingChallengeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String problemStatement;
  final String inputDescription;
  final String outputDescription;
  final List<String> constraints;
  final List<CodeExample> examples;
  final List<TestCase> sampleTestCases;
  final String difficulty;
  final String category;
  final List<String> supportedLanguages;
  final Map<String, String>
  codeTemplates; // e.g. 'dart', 'python', 'javascript'
  final int timeLimitSeconds;
  final int points;
  final List<String> hints;

  const CodingChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.problemStatement,
    required this.inputDescription,
    required this.outputDescription,
    this.constraints = const [],
    this.examples = const [],
    this.sampleTestCases = const [],
    this.difficulty = 'Beginner',
    this.category = 'Programming',
    this.supportedLanguages = const ['dart', 'python', 'javascript'],
    this.codeTemplates = const {},
    this.timeLimitSeconds = 1800,
    this.points = 100,
    this.hints = const [],
  });

  CodingChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? problemStatement,
    String? inputDescription,
    String? outputDescription,
    List<String>? constraints,
    List<CodeExample>? examples,
    List<TestCase>? sampleTestCases,
    String? difficulty,
    String? category,
    List<String>? supportedLanguages,
    Map<String, String>? codeTemplates,
    int? timeLimitSeconds,
    int? points,
    List<String>? hints,
  }) {
    return CodingChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      problemStatement: problemStatement ?? this.problemStatement,
      inputDescription: inputDescription ?? this.inputDescription,
      outputDescription: outputDescription ?? this.outputDescription,
      constraints: constraints ?? this.constraints,
      examples: examples ?? this.examples,
      sampleTestCases: sampleTestCases ?? this.sampleTestCases,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      codeTemplates: codeTemplates ?? this.codeTemplates,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      points: points ?? this.points,
      hints: hints ?? this.hints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'problemStatement': problemStatement,
      'inputDescription': inputDescription,
      'outputDescription': outputDescription,
      'constraints': constraints,
      'examples': examples.map((e) => e.toJson()).toList(),
      'sampleTestCases': sampleTestCases.map((e) => e.toJson()).toList(),
      'difficulty': difficulty,
      'category': category,
      'supportedLanguages': supportedLanguages,
      'codeTemplates': codeTemplates,
      'timeLimitSeconds': timeLimitSeconds,
      'points': points,
      'hints': hints,
    };
  }

  factory CodingChallengeModel.fromJson(Map<String, dynamic> json) {
    final rawExamples = json['examples'] as List<dynamic>? ?? [];
    final rawTestCases = json['sampleTestCases'] as List<dynamic>? ?? [];
    final rawTemplates = json['codeTemplates'] as Map<String, dynamic>? ?? {};

    return CodingChallengeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      problemStatement: json['problemStatement'] as String? ?? '',
      inputDescription: json['inputDescription'] as String? ?? '',
      outputDescription: json['outputDescription'] as String? ?? '',
      constraints:
          (json['constraints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      examples: rawExamples
          .map((e) => CodeExample.fromJson(e as Map<String, dynamic>))
          .toList(),
      sampleTestCases: rawTestCases
          .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
          .toList(),
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      category: json['category'] as String? ?? 'Programming',
      supportedLanguages:
          (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['dart', 'python', 'javascript'],
      codeTemplates: rawTemplates.map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 1800,
      points: (json['points'] as num?)?.toInt() ?? 100,
      hints:
          (json['hints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    problemStatement,
    inputDescription,
    outputDescription,
    constraints,
    examples,
    sampleTestCases,
    difficulty,
    category,
    supportedLanguages,
    codeTemplates,
    timeLimitSeconds,
    points,
    hints,
  ];
}
