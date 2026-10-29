// App-wide Constants
class AppConstants {
  AppConstants._();

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Quiz
  static const int defaultQuizTimeSeconds = 600; // 10 minutes
  static const int technicalQuizTimeSeconds = 900; // 15 minutes
  static const int codingChallengeTimeSeconds = 1800; // 30 minutes
  static const int pointsPerCorrectAnswer = 10;
  static const int bonusPointsPerfectScore = 50;
  static const double passingAccuracyThreshold = 0.6;

  // UI
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double avatarRadius = 24.0;
  static const double largeAvatarRadius = 48.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Padding
  static const double screenPadding = 20.0;

  // SharedPreferences Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyDemoLoggedIn = 'demo_logged_in';
  static const String keyCurrentUser = 'current_user';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySoundEffects = 'sound_effects';
  static const String keyHapticFeedback = 'haptic_feedback';
  static const String keyCompletedAttempts = 'completed_attempts';
  static const String keyCompletedChallenges = 'completed_challenges';
  static const String keyUserPoints = 'user_points';
  static const String keyUserStreak = 'user_streak';
  static const String keyRememberMe = 'remember_me';
  static const String keyRememberedEmail = 'remembered_email';
  static const String keyNotificationsList = 'notifications_list';
  static const String keyReadNotifications = 'read_notifications';
  static const String keyLastLoginDate = 'last_login_date';

  // Demo User
  static const String demoUserId = 'demo-user-001';
  static const String demoUserName = 'Alex Dev';
  static const String demoUsername = 'alexdev';
  static const String demoUserEmail = 'demo@dailyduel.com';
  static const String demoUserAvatar = 'A';

  // App Info
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Leaderboard
  static const int leaderboardPageSize = 20;
  static const int topRankCount = 3;

  // Onboarding
  static const int onboardingScreenCount = 3;

  // Categories
  static const List<String> challengeCategories = [
    'All',
    'General Knowledge',
    'Programming',
    'Cloud Computing',
    'DevOps',
    'Networking',
    'Databases',
    'Cybersecurity',
    'Aptitude',
    'Mathematics',
  ];

  static const List<String> difficultyLevels = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  static const List<String> challengeStatuses = [
    'All',
    'Available',
    'Completed',
    'In Progress',
    'Locked',
  ];
}
