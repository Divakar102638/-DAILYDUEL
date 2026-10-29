import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum NotificationType {
  dailyChallenge,
  challengeComplete,
  achievementUnlock,
  leaderboardUpdate,
  streak;

  String get displayName {
    switch (this) {
      case NotificationType.dailyChallenge:
        return 'Daily Challenge';
      case NotificationType.challengeComplete:
        return 'Challenge Completed';
      case NotificationType.achievementUnlock:
        return 'Achievement Unlocked';
      case NotificationType.leaderboardUpdate:
        return 'Leaderboard Update';
      case NotificationType.streak:
        return 'Streak Reminder';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.dailyChallenge:
        return Icons.bolt_rounded;
      case NotificationType.challengeComplete:
        return Icons.check_circle_outline_rounded;
      case NotificationType.achievementUnlock:
        return Icons.emoji_events_outlined;
      case NotificationType.leaderboardUpdate:
        return Icons.leaderboard_outlined;
      case NotificationType.streak:
        return Icons.local_fire_department_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.dailyChallenge:
        return AppColors.primaryBlue;
      case NotificationType.challengeComplete:
        return AppColors.successGreen;
      case NotificationType.achievementUnlock:
        return AppColors.warningAmber;
      case NotificationType.leaderboardUpdate:
        return AppColors.secondaryViolet;
      case NotificationType.streak:
        return AppColors.mathematicsColor;
    }
  }

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'challengecomplete':
        return NotificationType.challengeComplete;
      case 'achievementunlock':
        return NotificationType.achievementUnlock;
      case 'leaderboardupdate':
        return NotificationType.leaderboardUpdate;
      case 'streak':
        return NotificationType.streak;
      case 'dailychallenge':
      default:
        return NotificationType.dailyChallenge;
    }
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    type,
    isRead,
    createdAt,
    metadata,
  ];
}
