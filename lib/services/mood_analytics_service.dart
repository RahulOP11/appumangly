import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_models.dart';

class MoodAnalyticsService {
  static const String _collection = 'moodHistory';
  static const String _lastMoodKey = 'last_mood_date';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log mood entry to Firestore
  Future<void> logMoodEntry({
    required String userId,
    required MoodType mood,
    String? notes,
    String source = 'manual',
    double? confidence,
  }) async {
    try {
      final entry = MoodEntry(
        id: '', // Will be set by Firestore
        userId: userId,
        mood: mood,
        timestamp: DateTime.now(),
        notes: notes,
        source: source,
        confidence: confidence,
      );

      await _firestore.collection(_collection).add(entry.toFirestore());

      // Log to Firebase Analytics
      await _analytics.logEvent(
        name: 'mood_selected',
        parameters: {
          'mood': mood.label,
          'source': source,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Save today's mood to prevent duplicates
      await _saveTodaysMood(mood);
    } catch (e) {
      throw Exception('Failed to log mood entry: $e');
    }
  }

  // Check if mood was already logged today
  Future<bool> hasMoodLoggedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMoodDate = prefs.getString(_lastMoodKey);
    if (lastMoodDate == null) return false;
    
    final lastDate = DateTime.parse(lastMoodDate);
    final today = DateTime.now();
    
    return lastDate.year == today.year &&
           lastDate.month == today.month &&
           lastDate.day == today.day;
  }

  Future<void> _saveTodaysMood(MoodType mood) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastMoodKey, DateTime.now().toIso8601String());
    await prefs.setString('today_mood', mood.label);
  }

  Future<MoodType?> getTodaysMood() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLogged = await hasMoodLoggedToday();
    if (!hasLogged) return null;
    
    final moodLabel = prefs.getString('today_mood');
    if (moodLabel == null) return null;
    
    return MoodType.values.firstWhere(
      (m) => m.label == moodLabel,
      orElse: () => MoodType.okay,
    );
  }

  // Get mood history stream
  Stream<List<MoodEntry>> getMoodHistoryStream({
    required String userId,
    int? limit,
  }) {
    Query query = _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
    });
  }

  // Generate weekly mood summary
  Future<WeeklyMoodSummary> generateWeeklySummary({
    required String userId,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      final DateTime weekEnd = weekStart.add(const Duration(days: 6, hours: 23, minutes: 59));
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .orderBy('timestamp')
          .get();
      
      final moodCounts = <MoodType, int>{};
      final entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
      
      // Count moods
      for (final entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      
      // Find dominant mood
      MoodType? dominantMood;
      int maxCount = 0;
      for (final entry in moodCounts.entries) {
        if (entry.value > maxCount) {
          maxCount = entry.value;
          dominantMood = entry.key;
        }
      }
      
      // Calculate average mood score
      final moodValues = {
        MoodType.great: 5,
        MoodType.good: 4,
        MoodType.okay: 3,
        MoodType.low: 2,
        MoodType.sad: 1,
      };
      
      double totalScore = 0;
      for (final entry in entries) {
        totalScore += moodValues[entry.mood] ?? 3;
      }
      
      final averageScore = entries.isNotEmpty ? totalScore / entries.length : 3.0;
      
      // Calculate mood stability
      final stability = _calculateMoodStability(entries);
      
      // Generate insights and suggestions
      final insights = _generateInsights(moodCounts, dominantMood, averageScore);
      final suggestions = _generateSuggestions(dominantMood, averageScore, stability);
      
      return WeeklyMoodSummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        moodCounts: moodCounts,
        dominantMood: dominantMood,
        totalEntries: entries.length,
        averageMoodScore: averageScore,
        moodStability: stability,
        insights: insights,
        suggestions: suggestions,
      );
    } catch (e) {
      throw Exception('Failed to generate weekly summary: $e');
    }
  }

  double _calculateMoodStability(List<MoodEntry> entries) {
    if (entries.length < 2) return 1.0;
    
    final moodValues = {
      MoodType.great: 5,
      MoodType.good: 4,
      MoodType.okay: 3,
      MoodType.low: 2,
      MoodType.sad: 1,
    };
    
    final values = entries.map((e) => moodValues[e.mood]!.toDouble()).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / values.length;
    
    // Convert variance to stability score (0-1, where 1 is most stable)
    return 1.0 / (1.0 + variance);
  }

  List<String> _generateInsights(Map<MoodType, int> moodCounts, MoodType? dominantMood, double averageScore) {
    final insights = <String>[];
    
    if (dominantMood != null) {
      insights.add('Your dominant mood this week was ${dominantMood.emoji} ${dominantMood.label}');
    }
    
    if (averageScore >= 4.0) {
      insights.add('You had a positively energetic week! 🌟');
    } else if (averageScore <= 2.5) {
      insights.add('This week brought some challenges. Remember, it\'s okay to have difficult days.');
    } else {
      insights.add('You experienced a balanced range of emotions this week.');
    }
    
    final totalEntries = moodCounts.values.fold(0, (sum, count) => sum + count);
    if (totalEntries >= 5) {
      insights.add('Great job tracking your mood consistently! 📊');
    }
    
    return insights;
  }

  List<String> _generateSuggestions(MoodType? dominantMood, double averageScore, double stability) {
    final suggestions = <String>[];
    
    if (averageScore < 2.5) {
      suggestions.addAll([
        'Consider talking to a friend or counselor',
        'Try some gentle meditation or breathing exercises',
        'Take a walk in nature when possible',
      ]);
    } else if (averageScore > 4.0) {
      suggestions.addAll([
        'Keep up the positive momentum! 🎉',
        'Share your happiness with others',
        'Reflect on what\'s working well for you',
      ]);
    }
    
    if (stability < 0.5) {
      suggestions.add('Your moods varied quite a bit. Consider maintaining a regular routine.');
    }
    
    switch (dominantMood) {
      case MoodType.sad:
        suggestions.add('Practice self-compassion and reach out for support when needed');
        break;
      case MoodType.low:
        suggestions.add('Try engaging in small activities that usually bring you joy');
        break;
      case MoodType.great:
        suggestions.add('Continue doing what makes you feel great!');
        break;
      case MoodType.good:
        suggestions.add('You\'re in a good rhythm. Keep it up!');
        break;
      case MoodType.okay:
        suggestions.add('Look for small ways to add more joy to your days');
        break;
      case null:
        break;
    }
    
    return suggestions;
  }

  // Get mood streak (consecutive days of same mood category)
  Future<int> getCurrentMoodStreak({
    required String userId,
    required MoodType targetMood,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      
      final entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
      
      int streak = 0;
      for (final entry in entries) {
        if (entry.mood == targetMood) {
          streak++;
        } else {
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Get mood frequency over time period
  Future<Map<MoodType, double>> getMoodFrequency({
    required String userId,
    required int days,
  }) async {
    try {
      final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();
      
      final entries = snapshot.docs.map((doc) => MoodEntry.fromFirestore(doc)).toList();
      final moodCounts = <MoodType, int>{};
      
      for (final entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      
      final total = entries.length;
      final frequency = <MoodType, double>{};
      
      for (final mood in MoodType.values) {
        frequency[mood] = total > 0 ? (moodCounts[mood] ?? 0) / total : 0.0;
      }
      
      return frequency;
    } catch (e) {
      throw Exception('Failed to get mood frequency: $e');
    }
  }
}