import 'package:cloud_firestore/cloud_firestore.dart';

// Main diary entry model
class DiaryEntry {
  final String id;
  final String userId;
  final DateTime date;
  final String title;
  final String content;
  final List<String> tags;
  final DiaryMood mood;
  final List<DiaryMoment> moments;
  final List<PersonMention> peopleMentioned;
  final List<ThankYouNote> thankYouNotes;
  final List<String> photoUrls;
  final Weather? weather;
  final Location? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final double sentimentScore; // AI-generated sentiment analysis
  final List<String> aiTags; // AI-generated tags
  final String? aiSummary; // AI-generated summary

  DiaryEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.mood,
    this.moments = const [],
    this.peopleMentioned = const [],
    this.thankYouNotes = const [],
    this.photoUrls = const [],
    this.weather,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.sentimentScore = 0.0,
    this.aiTags = const [],
    this.aiSummary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'title': title,
      'content': content,
      'tags': tags,
      'mood': mood.toMap(),
      'moments': moments.map((m) => m.toMap()).toList(),
      'peopleMentioned': peopleMentioned.map((p) => p.toMap()).toList(),
      'thankYouNotes': thankYouNotes.map((t) => t.toMap()).toList(),
      'photoUrls': photoUrls,
      'weather': weather?.toMap(),
      'location': location?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isFavorite': isFavorite,
      'sentimentScore': sentimentScore,
      'aiTags': aiTags,
      'aiSummary': aiSummary,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      mood: DiaryMood.fromMap(map['mood'] ?? {}),
      moments: List<DiaryMoment>.from(
        (map['moments'] ?? []).map((m) => DiaryMoment.fromMap(m)),
      ),
      peopleMentioned: List<PersonMention>.from(
        (map['peopleMentioned'] ?? []).map((p) => PersonMention.fromMap(p)),
      ),
      thankYouNotes: List<ThankYouNote>.from(
        (map['thankYouNotes'] ?? []).map((t) => ThankYouNote.fromMap(t)),
      ),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      weather: map['weather'] != null ? Weather.fromMap(map['weather']) : null,
      location: map['location'] != null ? Location.fromMap(map['location']) : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isFavorite: map['isFavorite'] ?? false,
      sentimentScore: map['sentimentScore']?.toDouble() ?? 0.0,
      aiTags: List<String>.from(map['aiTags'] ?? []),
      aiSummary: map['aiSummary'],
    );
  }

  DiaryEntry copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DiaryMood? mood,
    List<DiaryMoment>? moments,
    List<PersonMention>? peopleMentioned,
    List<ThankYouNote>? thankYouNotes,
    List<String>? photoUrls,
    Weather? weather,
    Location? location,
    bool? isFavorite,
    double? sentimentScore,
    List<String>? aiTags,
    String? aiSummary,
  }) {
    return DiaryEntry(
      id: id,
      userId: userId,
      date: date,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      moments: moments ?? this.moments,
      peopleMentioned: peopleMentioned ?? this.peopleMentioned,
      thankYouNotes: thankYouNotes ?? this.thankYouNotes,
      photoUrls: photoUrls ?? this.photoUrls,
      weather: weather ?? this.weather,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isFavorite: isFavorite ?? this.isFavorite,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      aiTags: aiTags ?? this.aiTags,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }
}

// Mood tracking for diary entries
class DiaryMood {
  final MoodType type;
  final int intensity; // 1-10 scale
  final String? note;
  final List<String> emotions; // multiple emotions can be selected

  DiaryMood({
    required this.type,
    required this.intensity,
    this.note,
    this.emotions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'intensity': intensity,
      'note': note,
      'emotions': emotions,
    };
  }

  factory DiaryMood.fromMap(Map<String, dynamic> map) {
    return DiaryMood(
      type: MoodType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MoodType.neutral,
      ),
      intensity: map['intensity'] ?? 5,
      note: map['note'],
      emotions: List<String>.from(map['emotions'] ?? []),
    );
  }
}

// Enhanced mood types
enum MoodType {
  ecstatic,
  happy,
  content,
  neutral,
  sad,
  angry,
  anxious,
  excited,
  grateful,
  peaceful,
  confused,
  inspired,
}

// Best moments model
class DiaryMoment {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final List<String> tags;
  final Location? location;
  final List<String> peopleInvolved;
  final int happiness; // 1-10 scale
  final MomentType type;

  DiaryMoment({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.tags = const [],
    this.location,
    this.peopleInvolved = const [],
    this.happiness = 10,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'tags': tags,
      'location': location?.toMap(),
      'peopleInvolved': peopleInvolved,
      'happiness': happiness,
      'type': type.name,
    };
  }

  factory DiaryMoment.fromMap(Map<String, dynamic> map) {
    return DiaryMoment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      location: map['location'] != null ? Location.fromMap(map['location']) : null,
      peopleInvolved: List<String>.from(map['peopleInvolved'] ?? []),
      happiness: map['happiness'] ?? 10,
      type: MomentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MomentType.other,
      ),
    );
  }
}

enum MomentType {
  achievement,
  celebration,
  adventure,
  love,
  friendship,
  family,
  learning,
  creativity,
  nature,
  food,
  travel,
  surprise,
  kindness,
  other,
}

// People mentions model
class PersonMention {
  final String id;
  final String name;
  final String? relationship; // friend, family, colleague, etc.
  final String? photoUrl;
  final String? note; // what you did together or how they impacted your day
  final List<String> tags; // funny, supportive, inspiring, etc.
  final ContactInfo? contactInfo;

  PersonMention({
    required this.id,
    required this.name,
    this.relationship,
    this.photoUrl,
    this.note,
    this.tags = const [],
    this.contactInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'photoUrl': photoUrl,
      'note': note,
      'tags': tags,
      'contactInfo': contactInfo?.toMap(),
    };
  }

  factory PersonMention.fromMap(Map<String, dynamic> map) {
    return PersonMention(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      relationship: map['relationship'],
      photoUrl: map['photoUrl'],
      note: map['note'],
      tags: List<String>.from(map['tags'] ?? []),
      contactInfo: map['contactInfo'] != null 
        ? ContactInfo.fromMap(map['contactInfo']) 
        : null,
    );
  }
}

// Contact information for people
class ContactInfo {
  final String? phone;
  final String? email;
  final String? socialMedia;
  final String? address;

  ContactInfo({
    this.phone,
    this.email,
    this.socialMedia,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'socialMedia': socialMedia,
      'address': address,
    };
  }

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'],
      email: map['email'],
      socialMedia: map['socialMedia'],
      address: map['address'],
    );
  }
}

// Thank you notes model
class ThankYouNote {
  final String id;
  final String personName;
  final String? personId; // reference to PersonMention
  final String message;
  final String reason; // what you're thankful for
  final DateTime createdAt;
  final ThankYouType type;
  final bool isShared; // whether you've shared this with the person

  ThankYouNote({
    required this.id,
    required this.personName,
    this.personId,
    required this.message,
    required this.reason,
    required this.createdAt,
    required this.type,
    this.isShared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'personId': personId,
      'message': message,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'isShared': isShared,
    };
  }

  factory ThankYouNote.fromMap(Map<String, dynamic> map) {
    return ThankYouNote(
      id: map['id'] ?? '',
      personName: map['personName'] ?? '',
      personId: map['personId'],
      message: map['message'] ?? '',
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: ThankYouType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ThankYouType.general,
      ),
      isShared: map['isShared'] ?? false,
    );
  }
}

enum ThankYouType {
  help,
  support,
  kindness,
  gift,
  time,
  advice,
  inspiration,
  love,
  friendship,
  general,
}

// Weather model for context
class Weather {
  final String condition; // sunny, rainy, cloudy, etc.
  final int temperature;
  final String? description;

  Weather({
    required this.condition,
    required this.temperature,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'temperature': temperature,
      'description': description,
    };
  }

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      condition: map['condition'] ?? '',
      temperature: map['temperature'] ?? 0,
      description: map['description'],
    );
  }
}

// Location model for context
class Location {
  final String name;
  final double? latitude;
  final double? longitude;
  final String? address;

  Location({
    required this.name,
    this.latitude,
    this.longitude,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
    );
  }
}

// AI Writing prompts model
class WritingPrompt {
  final String id;
  final String prompt;
  final PromptCategory category;
  final List<String> tags;
  final int usageCount;

  WritingPrompt({
    required this.id,
    required this.prompt,
    required this.category,
    this.tags = const [],
    this.usageCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'category': category.name,
      'tags': tags,
      'usageCount': usageCount,
    };
  }

  factory WritingPrompt.fromMap(Map<String, dynamic> map) {
    return WritingPrompt(
      id: map['id'] ?? '',
      prompt: map['prompt'] ?? '',
      category: PromptCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => PromptCategory.general,
      ),
      tags: List<String>.from(map['tags'] ?? []),
      usageCount: map['usageCount'] ?? 0,
    );
  }
}

enum PromptCategory {
  reflection,
  gratitude,
  goals,
  memories,
  relationships,
  creativity,
  mindfulness,
  general,
}

// Diary analytics model
class DiaryAnalytics {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalEntries;
  final int totalWords;
  final int totalMoments;
  final int totalThankYouNotes;
  final Map<MoodType, int> moodDistribution;
  final Map<String, int> topTags;
  final Map<String, int> topPeople;
  final double averageSentiment;
  final int writingStreak;
  final int longestStreak;
  final List<String> topMemories;

  DiaryAnalytics({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalEntries,
    required this.totalWords,
    required this.totalMoments,
    required this.totalThankYouNotes,
    required this.moodDistribution,
    required this.topTags,
    required this.topPeople,
    required this.averageSentiment,
    required this.writingStreak,
    required this.longestStreak,
    required this.topMemories,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalEntries': totalEntries,
      'totalWords': totalWords,
      'totalMoments': totalMoments,
      'totalThankYouNotes': totalThankYouNotes,
      'moodDistribution': moodDistribution.map((k, v) => MapEntry(k.name, v)),
      'topTags': topTags,
      'topPeople': topPeople,
      'averageSentiment': averageSentiment,
      'writingStreak': writingStreak,
      'longestStreak': longestStreak,
      'topMemories': topMemories,
    };
  }
}