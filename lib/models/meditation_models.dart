class MeditationSession {
  final String id;
  final String title;
  final String duration;
  final String description;
  final String difficulty;
  final String category;
  final String audioUrl;
  final String imageUrl;
  final String instructor;
  final List<String> tags;
  final bool isFree;

  MeditationSession({
    required this.id,
    required this.title,
    required this.duration,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.audioUrl,
    required this.imageUrl,
    required this.instructor,
    required this.tags,
    this.isFree = true,
  });

  factory MeditationSession.fromJson(Map<String, dynamic> json) {
    return MeditationSession(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      instructor: json['instructor'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isFree: json['isFree'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'duration': duration,
      'description': description,
      'difficulty': difficulty,
      'category': category,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'instructor': instructor,
      'tags': tags,
      'isFree': isFree,
    };
  }
}

class BreathingPattern {
  final String name;
  final String description;
  final int inhale;
  final int hold;
  final int exhale;
  final String difficulty;

  BreathingPattern({
    required this.name,
    required this.description,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.difficulty,
  });

  String get cycleDescription => hold > 0 
      ? 'Inhale ${inhale}s - Hold ${hold}s - Exhale ${exhale}s'
      : 'Inhale ${inhale}s - Exhale ${exhale}s';
}

class SoundCategory {
  final String name;
  final String description;
  final String icon;
  final List<SoundTrack> tracks;

  SoundCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.tracks,
  });
}

class SoundTrack {
  final String id;
  final String name;
  final String url;
  final String duration;
  final bool isLooping;

  SoundTrack({
    required this.id,
    required this.name,
    required this.url,
    required this.duration,
    this.isLooping = true,
  });
}