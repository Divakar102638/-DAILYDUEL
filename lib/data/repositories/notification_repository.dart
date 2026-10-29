import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
  Future<void> addNotification(NotificationModel notification);
}

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({SharedPreferences? preferences})
    : _prefs = preferences {
    _initDefaultNotifications();
  }

  SharedPreferences? _prefs;
  final List<NotificationModel> _notifications = [];

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  void _initDefaultNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(
        id: 'notif-001',
        title: "Today's Challenges Are Live! ⚡",
        body:
            "Test your knowledge with World Trivia, Full-Stack Blitz, and the new Code Duel.",
        type: NotificationType.dailyChallenge,
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 45)),
        metadata: {'category': 'daily'},
      ),
      NotificationModel(
        id: 'notif-002',
        title: '🔥 7-Day Streak Active!',
        body:
            "You are on fire! Complete today's duel to push your streak closer to the 14-day milestone.",
        type: NotificationType.streak,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 3)),
        metadata: {'streak': 7},
      ),
      NotificationModel(
        id: 'notif-003',
        title: '🏆 Achievement Unlocked: Quiz Novice',
        body:
            'You completed your first 5 challenges with high accuracy! +50 bonus points awarded.',
        type: NotificationType.achievementUnlock,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        metadata: {'achievementId': 'ach-novice', 'bonusPoints': 50},
      ),
      NotificationModel(
        id: 'notif-004',
        title: 'Leaderboard Update 📊',
        body:
            'Marcus Vance claimed #2 on the weekly leaderboard. You are currently holding rank #12.',
        type: NotificationType.leaderboardUpdate,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 8)),
        metadata: {'rank': 12},
      ),
      NotificationModel(
        id: 'notif-005',
        title: 'Challenge Completed 🎉',
        body:
            'Great job! You finished the Networking & Protocols Sprint with 90% accuracy.',
        type: NotificationType.challengeComplete,
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
        metadata: {'score': 90, 'accuracy': 90.0},
      ),
    ]);
  }

  Future<void> _syncReadStateFromPrefs() async {
    final prefs = await _getPrefs();
    final readIds =
        prefs.getStringList(AppConstants.keyReadNotifications) ?? [];
    for (var i = 0; i < _notifications.length; i++) {
      if (readIds.contains(_notifications[i].id)) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _syncReadStateFromPrefs();
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<NotificationModel>.unmodifiable(_notifications);
  }

  @override
  Future<void> markAsRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      final prefs = await _getPrefs();
      final readIds =
          prefs.getStringList(AppConstants.keyReadNotifications) ?? [];
      if (!readIds.contains(id)) {
        readIds.add(id);
        await prefs.setStringList(AppConstants.keyReadNotifications, readIds);
      }
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final prefs = await _getPrefs();
    final allIds = <String>[];
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
      allIds.add(_notifications[i].id);
    }
    await prefs.setStringList(AppConstants.keyReadNotifications, allIds);
  }

  @override
  Future<int> getUnreadCount() async {
    await _syncReadStateFromPrefs();
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
  }
}
