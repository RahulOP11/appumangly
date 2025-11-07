import 'package:cloud_firestore/cloud_firestore.dart';

enum MoodType {
  great('Great', '😊', 'Positive Energy'),
  good('Good', '🙂', 'Balanced'),
  okay('OK', '😐', 'Neutral'),
  low('Low', '😞', 'Mild Down'),
  sad('Sad', '😢', 'Deep Emotional');

  const MoodType(this.label, this.emoji, this.category);
  
  final String label;
  final String emoji;
  final String category;
}

class MoodEntry {
  final String id;
  final String userId;
  final MoodType mood;
  final DateTime timestamp;
  final String? notes;
  final String source; // 'manual', 'ai_detection', 'voice'
  final double? confidence;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.timestamp,
    this.notes,
    this.source = 'manual',
    this.confidence,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mood': mood.label,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'source': source,
      'confidence': confidence,
      'createdAt': timestamp.toIso8601String(),
    };
  }

  static MoodEntry fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodEntry(
      id: doc.id,
      userId: data['userId'],
      mood: MoodType.values.firstWhere(
        (m) => m.label == data['mood'],
        orElse: () => MoodType.okay,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notes: data['notes'],
      source: data['source'] ?? 'manual',
      confidence: data['confidence']?.toDouble(),
    );
  }
}

class MoodResponse {
  final MoodType mood;
  final String message;
  final List<MoodAction> actions;
  final String backgroundGradient;
  final String? animationAsset;
  final String? soundAsset;

  MoodResponse({
    required this.mood,
    required this.message,
    required this.actions,
    required this.backgroundGradient,
    this.animationAsset,
    this.soundAsset,
  });
}

class MoodAction {
  final String title;
  final String description;
  final MoodActionType type;
  final Map<String, dynamic>? data;

  MoodAction({
    required this.title,
    required this.description,
    required this.type,
    this.data,
  });
}

enum MoodActionType {
  journal,
  meditation,
  quote,
  animation,
  gratitude,
  breathing,
  aiChat,
  voiceNote,
  resources,
  places,
  affirmation,
  releaseBox,
}

class WeeklyMoodSummary {
  final DateTime weekStart;
  final DateTime weekEnd;
  final Map<MoodType, int> moodCounts;
  final MoodType? dominantMood;
  final int totalEntries;
  final double averageMoodScore;
  final double moodStability;
  final List<String> insights;
  final List<String> suggestions;

  WeeklyMoodSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.moodCounts,
    this.dominantMood,
    required this.totalEntries,
    required this.averageMoodScore,
    required this.moodStability,
    required this.insights,
    required this.suggestions,
  });
}

class MoodTheme {
  final String backgroundColor;
  final String primaryColor;
  final String secondaryColor;
  final String textColor;
  final String recommendation;

  MoodTheme({
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.recommendation,
  });
}