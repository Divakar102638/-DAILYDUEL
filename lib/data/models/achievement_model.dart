import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AchievementCategory {
  challenge,
  streak,
  accuracy,
  social,
  special;

  String get displayName {
    switch (this) {
      case AchievementCategory.challenge:
        return 'Challenge';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.accuracy:
        return 'Accuracy';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  static AchievementCategory fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'streak':
        return AchievementCategory.streak;
      case 'accuracy':
        return AchievementCategory.accuracy;
      case 'social':
        return AchievementCategory.social;
      case 'special':
        return AchievementCategory.special;
      case 'challenge':
      default:
        return AchievementCategory.challenge;
    }
  }
}

class AchievementModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon; // Icon name e.g. 'emoji_events'
  final AchievementCategory category;
  final bool isUnlocked;
  final int progress;
  final int target;
  final DateTime? unlockedAt;
  final int points;
  final Color color;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.isUnlocked = false,
    this.progress = 0,
    required this.target,
    this.unlockedAt,
    this.points = 50,
    this.color = AppColors.primaryBlue,
  });

  double get progressPercentage =>
      target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementCategory? category,
    bool? isUnlocked,
    int? progress,
    int? target,
    DateTime? unlockedAt,
    int? points,
    Color? color,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category.name,
      'isUnlocked': isUnlocked,
      'progress': progress,
      'target': target,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'points': points,
      'color': color.toARGB32(),
    };
  }

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      category: AchievementCategory.fromString(json['category'] as String?),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 1,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
      points: (json['points'] as num?)?.toInt() ?? 50,
      color: json['color'] != null
          ? Color((json['color'] as num).toInt())
          : AppColors.primaryBlue,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    icon,
    category,
    isUnlocked,
    progress,
    target,
    unlockedAt,
    points,
    color,
  ];
}
