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