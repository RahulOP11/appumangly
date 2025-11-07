import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyMeditationVolume = 'meditation_volume';
  static const String _keyBreathingCycles = 'breathing_cycles';
  static const String _keyPreferredVoice = 'preferred_voice';
  static const String _keyBackgroundSound = 'background_sound';
  static const String _keyMeditationReminders = 'meditation_reminders';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyCompletedSessions = 'completed_sessions';
  static const String _keyTotalMeditationTime = 'total_meditation_time';

  // Volume settings
  static Future<void> setMeditationVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMeditationVolume, volume);
  }

  static Future<double> getMeditationVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMeditationVolume) ?? 0.7;
  }

  // Breathing exercise settings
  static Future<void> setBreathingCycles(int cycles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBreathingCycles, cycles);
  }

  static Future<int> getBreathingCycles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBreathingCycles) ?? 10;
  }

  // Voice preferences
  static Future<void> setPreferredVoice(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreferredVoice, voiceId);
  }

  static Future<String?> getPreferredVoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPreferredVoice);
  }

  // Background sound preferences
  static Future<void> setBackgroundSound(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBackgroundSound, soundId);
  }

  static Future<String?> getBackgroundSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBackgroundSound);
  }

  // Reminder settings
  static Future<void> setMeditationReminders(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMeditationReminders, enabled);
  }

  static Future<bool> getMeditationReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMeditationReminders) ?? false;
  }

  static Future<void> setReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyReminderTime, time);
  }

  static Future<String> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReminderTime) ?? '09:00';
  }

  // Progress tracking
  static Future<void> incrementCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCompletedSessions) ?? 0;
    await prefs.setInt(_keyCompletedSessions, current + 1);
  }

  static Future<int> getCompletedSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCompletedSessions) ?? 0;
  }

  static Future<void> addMeditationTime(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalMeditationTime) ?? 0;
    await prefs.setInt(_keyTotalMeditationTime, current + minutes);
  }

  static Future<int> getTotalMeditationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTotalMeditationTime) ?? 0;
  }

  // Favorite meditation sessions
  static Future<void> addFavoriteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_sessions') ?? [];
    if (!favorites.contains(sessionId)) {
      favorites.add(sessionId);
      await prefs.setStringList('favorite_sessions', favorites);
    }
  }

  static Future<void> removeFavoriteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorite_sessions') ?? [];
    favorites.remove(sessionId);
    await prefs.setStringList('favorite_sessions', favorites);
  }

  static Future<List<String>> getFavoriteSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favorite_sessions') ?? [];
  }

  static Future<bool> isFavoriteSession(String sessionId) async {
    final favorites = await getFavoriteSessions();
    return favorites.contains(sessionId);
  }

  // Session history
  static Future<void> addSessionToHistory(String sessionId, DateTime completedAt, int durationMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('session_history') ?? [];
    
    // Store as JSON-like string: "sessionId|timestamp|duration"
    String historyEntry = '$sessionId|${completedAt.millisecondsSinceEpoch}|$durationMinutes';
    history.add(historyEntry);
    
    // Keep only last 50 sessions
    if (history.length > 50) {
      history = history.sublist(history.length - 50);
    }
    
    await prefs.setStringList('session_history', history);
  }

  static Future<List<Map<String, dynamic>>> getSessionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('session_history') ?? [];
    
    return history.map((entry) {
      List<String> parts = entry.split('|');
      if (parts.length == 3) {
        return {
          'sessionId': parts[0],
          'completedAt': DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
          'durationMinutes': int.parse(parts[2]),
        };
      }
      return <String, dynamic>{};
    }).where((entry) => entry.isNotEmpty).toList();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Meditation streak tracking
  static Future<void> updateMeditationStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    final lastMeditationDate = prefs.getString('last_meditation_date');
    final currentStreak = prefs.getInt('meditation_streak') ?? 0;
    
    if (lastMeditationDate == todayString) {
      // Already meditated today, don't update streak
      return;
    }
    
    final yesterday = today.subtract(Duration(days: 1));
    final yesterdayString = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    
    if (lastMeditationDate == yesterdayString) {
      // Consecutive day, increment streak
      await prefs.setInt('meditation_streak', currentStreak + 1);
    } else {
      // Streak broken, reset to 1
      await prefs.setInt('meditation_streak', 1);
    }
    
    await prefs.setString('last_meditation_date', todayString);
  }

  static Future<int> getMeditationStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('meditation_streak') ?? 0;
  }
}