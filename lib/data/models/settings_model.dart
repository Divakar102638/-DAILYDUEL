import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  system;

  String get displayName {
    switch (this) {
      case AppThemeMode.dark:
        return 'Dark Mode';
      case AppThemeMode.light:
        return 'Light Mode';
      case AppThemeMode.system:
        return 'System Default';
    }
  }

  ThemeMode get toFlutterThemeMode {
    switch (this) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  static AppThemeMode fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }
}

class SettingsModel extends Equatable {
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final bool dailyChallengeReminder;
  final bool achievementAlerts;
  final bool leaderboardUpdates;
  final bool soundEffects;
  final bool hapticFeedback;
  final bool privacyShowProfile;
  final bool privacyShowStats;

  const SettingsModel({
    this.themeMode = AppThemeMode.dark,
    this.notificationsEnabled = true,
    this.dailyChallengeReminder = true,
    this.achievementAlerts = true,
    this.leaderboardUpdates = false,
    this.soundEffects = true,
    this.hapticFeedback = true,
    this.privacyShowProfile = true,
    this.privacyShowStats = true,
  });

  factory SettingsModel.defaultSettings() {
    return const SettingsModel();
  }

  SettingsModel copyWith({
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? dailyChallengeReminder,
    bool? achievementAlerts,
    bool? leaderboardUpdates,
    bool? soundEffects,
    bool? hapticFeedback,
    bool? privacyShowProfile,
    bool? privacyShowStats,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyChallengeReminder:
          dailyChallengeReminder ?? this.dailyChallengeReminder,
      achievementAlerts: achievementAlerts ?? this.achievementAlerts,
      leaderboardUpdates: leaderboardUpdates ?? this.leaderboardUpdates,
      soundEffects: soundEffects ?? this.soundEffects,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      privacyShowProfile: privacyShowProfile ?? this.privacyShowProfile,
      privacyShowStats: privacyShowStats ?? this.privacyShowStats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'notificationsEnabled': notificationsEnabled,
      'dailyChallengeReminder': dailyChallengeReminder,
      'achievementAlerts': achievementAlerts,
      'leaderboardUpdates': leaderboardUpdates,
      'soundEffects': soundEffects,
      'hapticFeedback': hapticFeedback,
      'privacyShowProfile': privacyShowProfile,
      'privacyShowStats': privacyShowStats,
    };
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      themeMode: AppThemeMode.fromString(json['themeMode'] as String?),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      dailyChallengeReminder: json['dailyChallengeReminder'] as bool? ?? true,
      achievementAlerts: json['achievementAlerts'] as bool? ?? true,
      leaderboardUpdates: json['leaderboardUpdates'] as bool? ?? false,
      soundEffects: json['soundEffects'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      privacyShowProfile: json['privacyShowProfile'] as bool? ?? true,
      privacyShowStats: json['privacyShowStats'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    dailyChallengeReminder,
    achievementAlerts,
    leaderboardUpdates,
    soundEffects,
    hapticFeedback,
    privacyShowProfile,
    privacyShowStats,
  ];
}
