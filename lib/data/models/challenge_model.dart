import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ChallengeCategory {
  generalKnowledge,
  programming,
  cloudComputing,
  devOps,
  networking,
  databases,
  cybersecurity,
  aptitude,
  mathematics;

  String get displayName {
    switch (this) {
      case ChallengeCategory.generalKnowledge:
        return 'General Knowledge';
      case ChallengeCategory.programming:
        return 'Programming';
      case ChallengeCategory.cloudComputing:
        return 'Cloud Computing';
      case ChallengeCategory.devOps:
        return 'DevOps';
      case ChallengeCategory.networking:
        return 'Networking';
      case ChallengeCategory.databases:
        return 'Databases';
      case ChallengeCategory.cybersecurity:
        return 'Cybersecurity';
      case ChallengeCategory.aptitude:
        return 'Aptitude';
      case ChallengeCategory.mathematics:
        return 'Mathematics';
    }
  }

  Color get color {
    switch (this) {
      case ChallengeCategory.generalKnowledge:
        return AppColors.generalKnowledgeColor;
      case ChallengeCategory.programming:
        return AppColors.programmingColor;
      case ChallengeCategory.cloudComputing:
        return AppColors.cloudComputingColor;
      case ChallengeCategory.devOps:
        return AppColors.devOpsColor;
      case ChallengeCategory.networking:
        return AppColors.networkingColor;
      case ChallengeCategory.databases:
        return AppColors.databasesColor;
      case ChallengeCategory.cybersecurity:
        return AppColors.cybersecurityColor;
      case ChallengeCategory.aptitude:
        return AppColors.aptitudeColor;
      case ChallengeCategory.mathematics:
        return AppColors.mathematicsColor;
    }
  }

  IconData get icon {
    switch (this) {
      case ChallengeCategory.generalKnowledge:
        return Icons.psychology_outlined;
      case ChallengeCategory.programming:
        return Icons.code_outlined;
      case ChallengeCategory.cloudComputing:
        return Icons.cloud_outlined;
      case ChallengeCategory.devOps:
        return Icons.all_inclusive_outlined;
      case ChallengeCategory.networking:
        return Icons.hub_outlined;
      case ChallengeCategory.databases:
        return Icons.storage_outlined;
      case ChallengeCategory.cybersecurity:
        return Icons.security_outlined;
      case ChallengeCategory.aptitude:
        return Icons.lightbulb_outlined;
      case ChallengeCategory.mathematics:
        return Icons.calculate_outlined;
    }
  }

  static ChallengeCategory fromString(String? value) {
    if (value == null) return ChallengeCategory.generalKnowledge;
    final normalized = value
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    for (final category in ChallengeCategory.values) {
      if (category.name.toLowerCase() == normalized ||
          category.displayName.toLowerCase().replaceAll(' ', '') ==
              normalized) {
        return category;
      }
    }
    return ChallengeCategory.generalKnowledge;
  }
}

enum ChallengeDifficulty {
  beginner,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case ChallengeDifficulty.beginner:
        return 'Beginner';
      case ChallengeDifficulty.intermediate:
        return 'Intermediate';
      case ChallengeDifficulty.advanced:
        return 'Advanced';
    }
  }

  Color get color {
    switch (this) {
      case ChallengeDifficulty.beginner:
        return AppColors.beginnerColor;
      case ChallengeDifficulty.intermediate:
        return AppColors.intermediateColor;
      case ChallengeDifficulty.advanced:
        return AppColors.advancedColor;
    }
  }

  static ChallengeDifficulty fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'intermediate':
        return ChallengeDifficulty.intermediate;
      case 'advanced':
        return ChallengeDifficulty.advanced;
      case 'beginner':
      default:
        return ChallengeDifficulty.beginner;
    }
  }
}

enum ChallengeStatus {
  available,
  inProgress,
  completed,
  locked,
  upcoming;

  String get displayName {
    switch (this) {
      case ChallengeStatus.available:
        return 'Available';
      case ChallengeStatus.inProgress:
        return 'In Progress';
      case ChallengeStatus.completed:
        return 'Completed';
      case ChallengeStatus.locked:
        return 'Locked';
      case ChallengeStatus.upcoming:
        return 'Upcoming';
    }
  }

  Color get color {
    switch (this) {
      case ChallengeStatus.available:
        return AppColors.primaryBlue;
      case ChallengeStatus.inProgress:
        return AppColors.warningAmber;
      case ChallengeStatus.completed:
        return AppColors.successGreen;
      case ChallengeStatus.locked:
        return AppColors.textDisabled;
      case ChallengeStatus.upcoming:
        return AppColors.infoBlue;
    }
  }

  static ChallengeStatus fromString(String? value) {
    switch (value?.toLowerCase().replaceAll(' ', '').replaceAll('_', '')) {
      case 'inprogress':
        return ChallengeStatus.inProgress;
      case 'completed':
        return ChallengeStatus.completed;
      case 'locked':
        return ChallengeStatus.locked;
      case 'upcoming':
        return ChallengeStatus.upcoming;
      case 'available':
      default:
        return ChallengeStatus.available;
    }
  }
}

enum ChallengeType {
  quiz,
  coding;

  String get displayName {
    switch (this) {
      case ChallengeType.quiz:
        return 'Quiz';
      case ChallengeType.coding:
        return 'Coding';
    }
  }

  static ChallengeType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'coding':
        return ChallengeType.coding;
      case 'quiz':
      default:
        return ChallengeType.quiz;
    }
  }
}

class ChallengeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final int questionCount;
  final int timeLimitSeconds;
  final int maxPoints;
  final List<String> supportedLanguages;
  final ChallengeType type;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? userScore;
  final double? userAccuracy;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.status = ChallengeStatus.available,
    this.questionCount = 10,
    this.timeLimitSeconds = 600,
    this.maxPoints = 100,
    this.supportedLanguages = const [],
    this.type = ChallengeType.quiz,
    this.startedAt,
    this.completedAt,
    this.userScore,
    this.userAccuracy,
  });

  bool get isCompleted => status == ChallengeStatus.completed;
  bool get isInProgress => status == ChallengeStatus.inProgress;
  bool get isLocked => status == ChallengeStatus.locked;
  bool get isAvailable => status == ChallengeStatus.available;
  bool get isCoding => type == ChallengeType.coding;
  bool get isQuiz => type == ChallengeType.quiz;

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    int? questionCount,
    int? timeLimitSeconds,
    int? maxPoints,
    List<String>? supportedLanguages,
    ChallengeType? type,
    DateTime? startedAt,
    DateTime? completedAt,
    int? userScore,
    double? userAccuracy,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      questionCount: questionCount ?? this.questionCount,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      maxPoints: maxPoints ?? this.maxPoints,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      userScore: userScore ?? this.userScore,
      userAccuracy: userAccuracy ?? this.userAccuracy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'questionCount': questionCount,
      'timeLimitSeconds': timeLimitSeconds,
      'maxPoints': maxPoints,
      'supportedLanguages': supportedLanguages,
      'type': type.name,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'userScore': userScore,
      'userAccuracy': userAccuracy,
    };
  }

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ChallengeCategory.fromString(json['category'] as String?),
      difficulty: ChallengeDifficulty.fromString(json['difficulty'] as String?),
      status: ChallengeStatus.fromString(json['status'] as String?),
      questionCount: (json['questionCount'] as num?)?.toInt() ?? 10,
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt() ?? 600,
      maxPoints: (json['maxPoints'] as num?)?.toInt() ?? 100,
      supportedLanguages:
          (json['supportedLanguages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      type: ChallengeType.fromString(json['type'] as String?),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      userScore: (json['userScore'] as num?)?.toInt(),
      userAccuracy: (json['userAccuracy'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    difficulty,
    status,
    questionCount,
    timeLimitSeconds,
    maxPoints,
    supportedLanguages,
    type,
    startedAt,
    completedAt,
    userScore,
    userAccuracy,
  ];
}
