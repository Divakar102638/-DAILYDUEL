import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/settings_model.dart';

class LocalSettingsRepository {
  LocalSettingsRepository({SharedPreferences? preferences})
    : _prefs = preferences;

  static const String _keyAppSettings = 'app_settings';
  static const String _keyDailyReminder = 'settings_daily_reminder';
  static const String _keyAchievementAlerts = 'settings_achievement_alerts';
  static const String _keyLeaderboardUpdates = 'settings_leaderboard_updates';
  static const String _keyPrivacyProfile = 'settings_privacy_profile';
  static const String _keyPrivacyStats = 'settings_privacy_stats';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<SettingsModel> getSettings() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyAppSettings);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        return SettingsModel.fromJson(data);
      } catch (_) {}
    }

    // Fallback to individual keys or defaults
    final themeStr = prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
    final notifsEnabled =
        prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    final dailyReminder = prefs.getBool(_keyDailyReminder) ?? true;
    final achAlerts = prefs.getBool(_keyAchievementAlerts) ?? true;
    final lbUpdates = prefs.getBool(_keyLeaderboardUpdates) ?? false;
    final sound = prefs.getBool(AppConstants.keySoundEffects) ?? true;
    final haptic = prefs.getBool(AppConstants.keyHapticFeedback) ?? true;
    final privacyProfile = prefs.getBool(_keyPrivacyProfile) ?? true;
    final privacyStats = prefs.getBool(_keyPrivacyStats) ?? true;

    return SettingsModel(
      themeMode: AppThemeMode.fromString(themeStr),
      notificationsEnabled: notifsEnabled,
      dailyChallengeReminder: dailyReminder,
      achievementAlerts: achAlerts,
      leaderboardUpdates: lbUpdates,
      soundEffects: sound,
      hapticFeedback: haptic,
      privacyShowProfile: privacyProfile,
      privacyShowStats: privacyStats,
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAppSettings, jsonEncode(settings.toJson()));
    await prefs.setString(AppConstants.keyThemeMode, settings.themeMode.name);
    await prefs.setBool(
      AppConstants.keyNotificationsEnabled,
      settings.notificationsEnabled,
    );
    await prefs.setBool(_keyDailyReminder, settings.dailyChallengeReminder);
    await prefs.setBool(_keyAchievementAlerts, settings.achievementAlerts);
    await prefs.setBool(_keyLeaderboardUpdates, settings.leaderboardUpdates);
    await prefs.setBool(AppConstants.keySoundEffects, settings.soundEffects);
    await prefs.setBool(
      AppConstants.keyHapticFeedback,
      settings.hapticFeedback,
    );
    await prefs.setBool(_keyPrivacyProfile, settings.privacyShowProfile);
    await prefs.setBool(_keyPrivacyStats, settings.privacyShowStats);
  }

  Future<String> getThemeMode() async {
    final prefs = await _getPrefs();
    return prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    final settings = await getSettings();
    final updated = settings.copyWith(themeMode: AppThemeMode.fromString(mode));
    await saveSettings(updated);
  }

  Future<bool> getNotificationsEnabled() async {
    final settings = await getSettings();
    return settings.notificationsEnabled;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(notificationsEnabled: enabled));
  }

  Future<bool> getDailyChallengeReminder() async {
    final settings = await getSettings();
    return settings.dailyChallengeReminder;
  }

  Future<void> setDailyChallengeReminder(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(dailyChallengeReminder: enabled));
  }

  Future<bool> getAchievementAlerts() async {
    final settings = await getSettings();
    return settings.achievementAlerts;
  }

  Future<void> setAchievementAlerts(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(achievementAlerts: enabled));
  }

  Future<bool> getLeaderboardUpdates() async {
    final settings = await getSettings();
    return settings.leaderboardUpdates;
  }

  Future<void> setLeaderboardUpdates(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(leaderboardUpdates: enabled));
  }

  Future<bool> getSoundEffects() async {
    final settings = await getSettings();
    return settings.soundEffects;
  }

  Future<void> setSoundEffects(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(soundEffects: enabled));
  }

  Future<bool> getHapticFeedback() async {
    final settings = await getSettings();
    return settings.hapticFeedback;
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(hapticFeedback: enabled));
  }

  Future<bool> getPrivacyShowProfile() async {
    final settings = await getSettings();
    return settings.privacyShowProfile;
  }

  Future<void> setPrivacyShowProfile(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(privacyShowProfile: enabled));
  }

  Future<bool> getPrivacyShowStats() async {
    final settings = await getSettings();
    return settings.privacyShowStats;
  }

  Future<void> setPrivacyShowStats(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(privacyShowStats: enabled));
  }
}
