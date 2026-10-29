import '../models/notification_model.dart';

List<NotificationModel> getMockNotifications() {
  final now = DateTime.now();

  return [
    NotificationModel(
      id: 'notif-001',
      title: 'New Daily Challenges are Live! ⚡',
      body:
          'Today\'s challenges in General Knowledge, Full-Stack Blitz, and Coding are ready. Jump in now!',
      type: NotificationType.dailyChallenge,
      isRead: false,
      createdAt: now.subtract(const Duration(minutes: 45)),
      metadata: const {'challengeId': 'challenge-daily-gk'},
    ),
    NotificationModel(
      id: 'notif-002',
      title: '7-Day Streak Maintained! 🔥',
      body:
          'Incredible consistency! You\'ve kept your streak burning for a full week. +50 bonus points!',
      type: NotificationType.streak,
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 3)),
      metadata: {'streakDays': 7, 'bonusPoints': 50},
    ),
    NotificationModel(
      id: 'notif-003',
      title: 'Achievement Unlocked: Speed Demon ⚡',
      body:
          'You completed the Full-Stack Blitz quiz in under 3 minutes with 90% accuracy.',
      type: NotificationType.achievementUnlock,
      isRead: false,
      createdAt: now.subtract(const Duration(hours: 6)),
      metadata: {'achievementId': 'ach-008'},
    ),
    NotificationModel(
      id: 'notif-004',
      title: 'Weekly Leaderboard Climb! 📈',
      body:
          'You moved up 3 spots to #12 on the Weekly Leaderboard! Only 30 points to the top 10.',
      type: NotificationType.leaderboardUpdate,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      metadata: {'previousRank': 15, 'currentRank': 12},
    ),
    NotificationModel(
      id: 'notif-005',
      title: 'Challenge Completed: Networking & Protocols',
      body:
          'You earned 90 points with a 90% score on Networking & Protocols Sprint.',
      type: NotificationType.challengeComplete,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 1, hours: 8)),
      metadata: {'challengeId': 'challenge-net-01', 'score': 90},
    ),
    NotificationModel(
      id: 'notif-006',
      title: 'Streak Warning! ⚠️',
      body:
          'Don\'t break your streak! Only 2 hours remaining to complete today\'s challenge.',
      type: NotificationType.streak,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 2)),
      metadata: {'streakDays': 6},
    ),
    NotificationModel(
      id: 'notif-007',
      title: 'Achievement Unlocked: Coding Beginner 💻',
      body:
          'You solved your first algorithmic challenge and earned 60 bonus XP points.',
      type: NotificationType.achievementUnlock,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 3)),
      metadata: {'achievementId': 'ach-006'},
    ),
    NotificationModel(
      id: 'notif-008',
      title: 'Daily Duel Reset Notice',
      body:
          'New competitive cycle started. Global rankings have been refreshed.',
      type: NotificationType.dailyChallenge,
      isRead: true,
      createdAt: now.subtract(const Duration(days: 4)),
    ),
  ];
}

final List<NotificationModel> mockNotifications = getMockNotifications();

int getUnreadNotificationCount() {
  return mockNotifications.where((n) => !n.isRead).length;
}
