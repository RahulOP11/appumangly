import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/smile_models.dart';

class SmileTrackerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _smileDataCollection = 'smile_daily_data';
  static const String _smileStreaksCollection = 'smile_streaks';

  /// Record smiles for a user on today's date
  Future<void> recordSmiles(String userId, int smileCount) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final pointsEarned = smileCount * 10; // 10 points per smile
    
    final smileData = SmileDayData(
      userId: userId,
      date: today,
      smileCount: smileCount,
      pointsEarned: pointsEarned,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save daily smile data
    await _firestore
        .collection(_smileDataCollection)
        .doc('${userId}_$dateKey')
        .set(smileData.toMap(), SetOptions(merge: true));

    // Update streak
    await _updateStreak(userId, today, smileCount > 0);
  }

  /// Get today's smile data for a user
  Future<SmileDayData?> getTodaySmileData(String userId) async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      final doc = await _firestore
          .collection(_smileDataCollection)
          .doc('${userId}_$dateKey')
          .get();

      if (doc.exists) {
        return SmileDayData.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting today\'s smile data: $e');
      return null;
    }
  }

  /// Get current streak for a user
  Future<int> getCurrentStreak(String userId) async {
    try {
      final doc = await _firestore
          .collection(_smileStreaksCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final streak = SmileStreak.fromMap(doc.data()!);
        return streak.currentStreak;
      }
      return 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  /// Get weekly stats for a user
  Future<SmileWeeklyStats> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    try {
      final query = await _firestore
          .collection(_smileDataCollection)
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfWeek.toIso8601String().split('T')[0])
          .where('date', isLessThanOrEqualTo: endOfWeek.toIso8601String().split('T')[0])
          .get();

      final dailyData = query.docs
          .map((doc) => SmileDayData.fromMap(doc.data()))
          .toList();

      final totalSmiles = dailyData.fold(0, (sum, data) => sum + data.smileCount);
      final totalPoints = dailyData.fold(0, (sum, data) => sum + data.pointsEarned);
      final daysActive = dailyData.where((data) => data.smileCount > 0).length;

      return SmileWeeklyStats(
        totalSmiles: totalSmiles,
        totalPoints: totalPoints,
        daysActive: daysActive,
        dailyData: dailyData,
      );
    } catch (e) {
      print('Error getting weekly stats: $e');
      return SmileWeeklyStats(
        totalSmiles: 0,
        totalPoints: 0,
        daysActive: 0,
        dailyData: [],
      );
    }
  }

  /// Update user's smile streak
  Future<void> _updateStreak(String userId, DateTime today, bool hasSmiles) async {
    try {
      final doc = await _firestore
          .collection(_smileStreaksCollection)
          .doc(userId)
          .get();

      SmileStreak currentStreak;
      if (doc.exists) {
        currentStreak = SmileStreak.fromMap(doc.data()!);
      } else {
        currentStreak = SmileStreak(
          currentStreak: 0,
          longestStreak: 0,
        );
      }

      // Calculate new streak
      int newCurrentStreak = currentStreak.currentStreak;
      int newLongestStreak = currentStreak.longestStreak;

      if (hasSmiles) {
        // Check if this continues the streak or starts a new one
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        
        final yesterdayDoc = await _firestore
            .collection(_smileDataCollection)
            .doc('${userId}_$yesterdayKey')
            .get();

        if (currentStreak.lastActiveDate != null) {
          final daysDiff = today.difference(currentStreak.lastActiveDate!).inDays;
          
          if (daysDiff == 1) {
            // Continue streak
            newCurrentStreak += 1;
          } else if (daysDiff == 0) {
            // Same day, keep current streak
            newCurrentStreak = currentStreak.currentStreak;
          } else {
            // Streak broken, start new
            newCurrentStreak = 1;
          }
        } else {
          // First time or no previous activity
          newCurrentStreak = 1;
        }

        // Update longest streak if necessary
        if (newCurrentStreak > newLongestStreak) {
          newLongestStreak = newCurrentStreak;
        }
      } else {
        // No smiles today, but don't reset streak immediately
        // Only reset if it's been more than a day since last activity
        if (currentStreak.lastActiveDate != null) {
          final daysSinceLastActive = today.difference(currentStreak.lastActiveDate!).inDays;
          if (daysSinceLastActive > 1) {
            newCurrentStreak = 0;
          }
        }
      }

      final updatedStreak = SmileStreak(
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        lastActiveDate: hasSmiles ? today : currentStreak.lastActiveDate,
      );

      await _firestore
          .collection(_smileStreaksCollection)
          .doc(userId)
          .set(updatedStreak.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// Get total points for a user
  Future<int> getTotalPoints(String userId) async {
    try {
      final query = await _firestore
          .collection(_smileDataCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final totalPoints = query.docs.fold(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['pointsEarned'] as int? ?? 0);
      });

      return totalPoints;
    } catch (e) {
      print('Error getting total points: $e');
      return 0;
    }
  }
}