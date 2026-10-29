import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ActivityType {
  quiz,
  coding;

  String get displayName {
    switch (this) {
      case ActivityType.quiz:
        return 'Quiz';
      case ActivityType.coding:
        return 'Coding';
    }
  }

  static ActivityType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'coding':
        return ActivityType.coding;
      case 'quiz':
      default:
        return ActivityType.quiz;
    }
  }
}

enum ActivityStatus {
  completed,
  incomplete,
  abandoned;

  String get displayName {
    switch (this) {
      case ActivityStatus.completed:
        return 'Completed';
      case ActivityStatus.incomplete:
        return 'Incomplete';
      case ActivityStatus.abandoned:
        return 'Abandoned';
    }
  }

  Color get color {
    switch (this) {
      case ActivityStatus.completed:
        return AppColors.successGreen;
      case ActivityStatus.incomplete:
        return AppColors.warningAmber;
      case ActivityStatus.abandoned:
        return AppColors.errorRed;
    }
  }

  static ActivityStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'incomplete':
        return ActivityStatus.incomplete;
      case 'abandoned':
        return ActivityStatus.abandoned;
      case 'completed':
      default:
        return ActivityStatus.completed;
    }
  }
}

class ActivityModel extends Equatable {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String userId;
  final ActivityType type;
  final ActivityStatus status;
  final int score;
  final double accuracy;
  final int pointsEarned;
  final int timeTakenSeconds;
  final DateTime completedAt;
  final String category;
  final String difficulty;

  const ActivityModel({
    required this.id,
    required this.challengeId,
    required this.challengeTitle,
    required this.userId,
    this.type = ActivityType.quiz,
    this.status = ActivityStatus.completed,
    this.score = 0,
    this.accuracy = 0.0,
    this.pointsEarned = 0,
    this.timeTakenSeconds = 0,
    required this.completedAt,
    required this.category,
    required this.difficulty,
  });

  ActivityModel copyWith({
    String? id,
    String? challengeId,
    String? challengeTitle,
    String? userId,
    ActivityType? type,
    ActivityStatus? status,
    int? score,
    double? accuracy,
    int? pointsEarned,
    int? timeTakenSeconds,
    DateTime? completedAt,
    String? category,
    String? difficulty,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      timeTakenSeconds: timeTakenSeconds ?? this.timeTakenSeconds,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'score': score,
      'accuracy': accuracy,
      'pointsEarned': pointsEarned,
      'timeTakenSeconds': timeTakenSeconds,
      'completedAt': completedAt.toIso8601String(),
      'category': category,
      'difficulty': difficulty,
    };
  }

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String? ?? '',
      challengeId: json['challengeId'] as String? ?? '',
      challengeTitle: json['challengeTitle'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: ActivityType.fromString(json['type'] as String?),
      status: ActivityStatus.fromString(json['status'] as String?),
      score: (json['score'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      timeTakenSeconds: (json['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    challengeId,
    challengeTitle,
    userId,
    type,
    status,
    score,
    accuracy,
    pointsEarned,
    timeTakenSeconds,
    completedAt,
    category,
    difficulty,
  ];
}
