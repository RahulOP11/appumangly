class SmileDetectionResult {
  final bool isSmiling;
  final double smileConfidence;
  final DateTime timestamp;
  final int pointsEarned;

  SmileDetectionResult({
    required this.isSmiling,
    required this.smileConfidence,
    required this.timestamp,
    required this.pointsEarned,
  });

  Map<String, dynamic> toJson() {
    return {
      'isSmiling': isSmiling,
      'smileConfidence': smileConfidence,
      'timestamp': timestamp.toIso8601String(),
      'pointsEarned': pointsEarned,
    };
  }

  factory SmileDetectionResult.fromJson(Map<String, dynamic> json) {
    return SmileDetectionResult(
      isSmiling: json['isSmiling'],
      smileConfidence: json['smileConfidence'],
      timestamp: DateTime.parse(json['timestamp']),
      pointsEarned: json['pointsEarned'],
    );
  }
}

class SmileReward {
  final String title;
  final String description;
  final int points;
  final String emoji;
  final RewardType type;

  SmileReward({
    required this.title,
    required this.description,
    required this.points,
    required this.emoji,
    required this.type,
  });
}

enum RewardType {
  firstSmile,
  dailyGoal,
  streak,
  bigSmile,
  consistency,
  milestone,
}

class UserSmileStats {
  final int totalPoints;
  final int dailySmiles;
  final int streakDays;
  final int totalSmiles;
  final DateTime lastSmileTime;
  final List<SmileDetectionResult> todaySmiles;

  UserSmileStats({
    required this.totalPoints,
    required this.dailySmiles,
    required this.streakDays,
    required this.totalSmiles,
    required this.lastSmileTime,
    required this.todaySmiles,
  });

  factory UserSmileStats.empty() {
    return UserSmileStats(
      totalPoints: 0,
      dailySmiles: 0,
      streakDays: 0,
      totalSmiles: 0,
      lastSmileTime: DateTime.now().subtract(Duration(days: 1)),
      todaySmiles: [],
    );
  }
}

class SmileDayData {
  final String userId;
  final DateTime date;
  final int smileCount;
  final int pointsEarned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SmileDayData({
    required this.userId,
    required this.date,
    required this.smileCount,
    required this.pointsEarned,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'smileCount': smileCount,
      'pointsEarned': pointsEarned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SmileDayData.fromMap(Map<String, dynamic> map) {
    return SmileDayData(
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      smileCount: map['smileCount'] ?? 0,
      pointsEarned: map['pointsEarned'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

class SmileWeeklyStats {
  final int totalSmiles;
  final int totalPoints;
  final int daysActive;
  final List<SmileDayData> dailyData;

  SmileWeeklyStats({
    required this.totalSmiles,
    required this.totalPoints,
    required this.daysActive,
    required this.dailyData,
  });
}

class SmileStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  SmileStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
    };
  }

  factory SmileStreak.fromMap(Map<String, dynamic> map) {
    return SmileStreak(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActiveDate: map['lastActiveDate'] != null 
          ? DateTime.parse(map['lastActiveDate']) 
          : null,
    );
  }
}