import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/smile_models.dart';

class SmileRewardsService {
  static const String _keyTotalPoints = 'smile_total_points';
  static const String _keyDailySmiles = 'smile_daily_smiles';
  static const String _keyStreakDays = 'smile_streak_days';
  static const String _keyTotalSmiles = 'smile_total_smiles';
  static const String _keyLastSmileDate = 'smile_last_smile_date';
  static const String _keyTodaySmiles = 'smile_today_smiles';

  static final List<SmileReward> _availableRewards = [
    SmileReward(
      title: 'First Smile!',
      description: 'Your very first smile of the day!',
      points: 50,
      emoji: '🌟',
      type: RewardType.firstSmile,
    ),
    SmileReward(
      title: 'Smile Streak!',
      description: '7 days of daily smiles',
      points: 200,
      emoji: '🔥',
      type: RewardType.streak,
    ),
    SmileReward(
      title: 'Big Smile!',
      description: 'That was an amazing smile!',
      points: 25,
      emoji: '😄',
      type: RewardType.bigSmile,
    ),
    SmileReward(
      title: 'Daily Goal!',
      description: '10 smiles in one day',
      points: 100,
      emoji: '🎯',
      type: RewardType.dailyGoal,
    ),
    SmileReward(
      title: 'Smile Master!',
      description: '100 total smiles',
      points: 500,
      emoji: '👑',
      type: RewardType.milestone,
    ),
  ];

  static Future<UserSmileStats> getUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final totalPoints = prefs.getInt(_keyTotalPoints) ?? 0;
      final dailySmiles = prefs.getInt(_keyDailySmiles) ?? 0;
      final streakDays = prefs.getInt(_keyStreakDays) ?? 0;
      final totalSmiles = prefs.getInt(_keyTotalSmiles) ?? 0;
      
      final lastSmileDateString = prefs.getString(_keyLastSmileDate);
      final lastSmileTime = lastSmileDateString != null 
          ? DateTime.parse(lastSmileDateString)
          : DateTime.now().subtract(Duration(days: 1));

      final todaysSmilesJson = prefs.getStringList(_keyTodaySmiles) ?? [];
      final todaySmiles = todaysSmilesJson.map((jsonString) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return SmileDetectionResult.fromJson(json);
      }).toList();

      return UserSmileStats(
        totalPoints: totalPoints,
        dailySmiles: dailySmiles,
        streakDays: streakDays,
        totalSmiles: totalSmiles,
        lastSmileTime: lastSmileTime,
        todaySmiles: todaySmiles,
      );
    } catch (e) {
      print('Error loading user stats: $e');
      return UserSmileStats.empty();
    }
  }

  static Future<List<SmileReward>> processSmileDetection(SmileDetectionResult result) async {
    if (!result.isSmiling) return [];

    final prefs = await SharedPreferences.getInstance();
    final currentStats = await getUserStats();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSmileDay = DateTime(
      currentStats.lastSmileTime.year,
      currentStats.lastSmileTime.month,
      currentStats.lastSmileTime.day,
    );

    int newDailySmiles = currentStats.dailySmiles;
    if (today == lastSmileDay) {
      newDailySmiles += 1;
    } else {
      newDailySmiles = 1;
    }

    int newStreakDays = currentStats.streakDays;
    if (today.difference(lastSmileDay).inDays == 1) {
      newStreakDays += 1;
    } else if (today != lastSmileDay) {
      newStreakDays = 1;
    }

    final newTotalSmiles = currentStats.totalSmiles + 1;
    int newTotalPoints = currentStats.totalPoints + result.pointsEarned;

    List<SmileReward> earnedRewards = [];

    // First smile of the day
    if (newDailySmiles == 1 && today != lastSmileDay) {
      final reward = _availableRewards.firstWhere((r) => r.type == RewardType.firstSmile);
      earnedRewards.add(reward);
      newTotalPoints += reward.points;
    }

    // Big smile reward
    if (result.smileConfidence >= 0.95) {
      final reward = _availableRewards.firstWhere((r) => r.type == RewardType.bigSmile);
      earnedRewards.add(reward);
      newTotalPoints += reward.points;
    }

    // Daily goal (10 smiles)
    if (newDailySmiles == 10) {
      final reward = _availableRewards.firstWhere((r) => r.type == RewardType.dailyGoal);
      earnedRewards.add(reward);
      newTotalPoints += reward.points;
    }

    // Streak reward (7 days)
    if (newStreakDays == 7) {
      final reward = _availableRewards.firstWhere((r) => r.type == RewardType.streak);
      earnedRewards.add(reward);
      newTotalPoints += reward.points;
    }

    // Milestone reward (100 smiles)
    if (newTotalSmiles == 100) {
      final reward = _availableRewards.firstWhere((r) => r.type == RewardType.milestone);
      earnedRewards.add(reward);
      newTotalPoints += reward.points;
    }

    // Save updated stats
    await prefs.setInt(_keyTotalPoints, newTotalPoints);
    await prefs.setInt(_keyDailySmiles, newDailySmiles);
    await prefs.setInt(_keyStreakDays, newStreakDays);
    await prefs.setInt(_keyTotalSmiles, newTotalSmiles);
    await prefs.setString(_keyLastSmileDate, now.toIso8601String());

    // Save today's smiles
    final updatedTodaySmiles = [...currentStats.todaySmiles, result];
    final todaysSmilesJson = updatedTodaySmiles.map((smile) => jsonEncode(smile.toJson())).toList();
    await prefs.setStringList(_keyTodaySmiles, todaysSmilesJson);

    return earnedRewards;
  }

  static Future<void> resetDailyStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailySmiles, 0);
    await prefs.setStringList(_keyTodaySmiles, []);
  }
}