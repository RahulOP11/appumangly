import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/mood_models.dart';

class MoodResponseHandler {
  static const Map<MoodType, List<String>> _moodQuotes = {
    MoodType.great: [
      "Your energy is contagious! ✨",
      "You're radiating positivity today! 🌟",
      "Keep shining bright! 💫",
      "Your joy is beautiful! 🌈",
    ],
    MoodType.good: [
      "I'm grateful for small joys. 🌸",
      "Today brings gentle contentment. 🕊️",
      "Steady progress is still progress. 🌱",
      "You're finding your rhythm! 🎵",
    ],
    MoodType.okay: [
      "It's okay to have neutral days. 🌤️",
      "Every day doesn't have to be extraordinary. ☁️",
      "You're exactly where you need to be. 🍃",
      "Tomorrow is a new opportunity. 🌅",
    ],
    MoodType.low: [
      "It's okay to have low days — they pass. 🌙",
      "You're stronger than you know. 💙",
      "This feeling is temporary. 🌊",
      "Be gentle with yourself today. 🤗",
    ],
    MoodType.sad: [
      "You're not alone in this. 💜",
      "It's brave to feel your emotions. 🌷",
      "Healing takes time, and that's okay. 🕊️",
      "Your feelings are valid. 💙",
    ],
  };

  static const Map<MoodType, List<String>> _journalPrompts = {
    MoodType.great: [
      "What made you feel great today?",
      "How can you share this positive energy?",
      "What are you most grateful for right now?",
    ],
    MoodType.good: [
      "What's one thing that made today good?",
      "What small joy did you notice today?",
      "How did you take care of yourself today?",
    ],
    MoodType.okay: [
      "What would make your day a bit better?",
      "What's one thing you're looking forward to?",
      "How are you feeling in this moment?",
    ],
    MoodType.low: [
      "What's weighing on you today?",
      "What do you need to feel a little lighter?",
      "Who or what brings you comfort?",
    ],
    MoodType.sad: [
      "What would you tell a friend feeling this way?",
      "What's one small thing that might help right now?",
      "How can you be gentle with yourself today?",
    ],
  };

  static MoodResponse getMoodResponse(MoodType mood) {
    switch (mood) {
      case MoodType.great:
        return MoodResponse(
          mood: mood,
          message: _getRandomQuote(mood),
          actions: [
            MoodAction(
              title: "🎉 Celebrate",
              description: "Show confetti animation",
              type: MoodActionType.animation,
              data: {'animation': 'confetti'},
            ),
            MoodAction(
              title: "🌸 Gratitude Card",
              description: "What made you feel great today?",
              type: MoodActionType.gratitude,
              data: {'prompt': _getRandomJournalPrompt(mood)},
            ),
            MoodAction(
              title: "🌻 Mind Garden",
              description: "Add a flower to your mind garden",
              type: MoodActionType.animation,
              data: {'animation': 'flower_bloom'},
            ),
          ],
          backgroundGradient: 'bright_yellow',
          animationAsset: 'assets/animations/confetti.json',
          soundAsset: 'assets/sounds/nature/birds_chirping.mp3',
        );

      case MoodType.good:
        return MoodResponse(
          mood: mood,
          message: _getRandomQuote(mood),
          actions: [
            MoodAction(
              title: "📝 Journal",
              description: _getRandomJournalPrompt(mood),
              type: MoodActionType.journal,
            ),
            MoodAction(
              title: "🧘 5-Minute Boost",
              description: "Quick meditation session",
              type: MoodActionType.meditation,
              data: {'duration': 5, 'type': 'boost'},
            ),
            MoodAction(
              title: "💫 Daily Affirmation",
              description: "I'm grateful for small joys",
              type: MoodActionType.affirmation,
            ),
          ],
          backgroundGradient: 'sky_blue',
          animationAsset: 'assets/animations/gentle_breeze.json',
        );

      case MoodType.okay:
        return MoodResponse(
          mood: mood,
          message: _getRandomQuote(mood),
          actions: [
            MoodAction(
              title: "💭 Reflect",
              description: _getRandomJournalPrompt(mood),
              type: MoodActionType.journal,
            ),
            MoodAction(
              title: "🌬️ Breathing Exercise",
              description: "Simple breathing technique",
              type: MoodActionType.breathing,
              data: {'pattern': '4-7-8', 'cycles': 5},
            ),
            MoodAction(
              title: "💡 Mood Lift Cards",
              description: "Inspiring quotes and tips",
              type: MoodActionType.quote,
            ),
          ],
          backgroundGradient: 'soft_beige',
          animationAsset: 'assets/animations/calm_waves.json',
        );

      case MoodType.low:
        return MoodResponse(
          mood: mood,
          message: _getRandomQuote(mood),
          actions: [
            MoodAction(
              title: "🌧️ Gentle Meditation",
              description: "Calming meditation with rain sounds",
              type: MoodActionType.meditation,
              data: {'duration': 10, 'type': 'calming', 'background': 'rain'},
            ),
            MoodAction(
              title: "📝 Release Box",
              description: "Write or speak what's weighing on you",
              type: MoodActionType.releaseBox,
            ),
            MoodAction(
              title: "🏞️ Calm Places",
              description: "Find peaceful places nearby",
              type: MoodActionType.places,
            ),
          ],
          backgroundGradient: 'cool_gray',
          animationAsset: 'assets/animations/gentle_rain.json',
          soundAsset: 'assets/sounds/nature/rain.mp3',
        );

      case MoodType.sad:
        return MoodResponse(
          mood: mood,
          message: _getRandomQuote(mood),
          actions: [
            MoodAction(
              title: "🤗 Self-Compassion",
              description: "Guided self-compassion meditation",
              type: MoodActionType.meditation,
              data: {'duration': 15, 'type': 'compassion'},
            ),
            MoodAction(
              title: "💬 AI Mood Mentor",
              description: "Talk with our empathetic AI companion",
              type: MoodActionType.aiChat,
            ),
            MoodAction(
              title: "🎙️ Voice Release",
              description: "Record your feelings as a floating light",
              type: MoodActionType.voiceNote,
            ),
            MoodAction(
              title: "🆘 Get Support",
              description: "Mental health resources and helplines",
              type: MoodActionType.resources,
            ),
          ],
          backgroundGradient: 'deep_navy',
          animationAsset: 'assets/animations/comfort_embrace.json',
          soundAsset: 'assets/sounds/ambient/healing_tones.mp3',
        );
    }
  }

  static String _getRandomQuote(MoodType mood) {
    final quotes = _moodQuotes[mood] ?? [];
    if (quotes.isEmpty) return "You matter. 💙";
    return quotes[(DateTime.now().millisecondsSinceEpoch % quotes.length)];
  }

  static String _getRandomJournalPrompt(MoodType mood) {
    final prompts = _journalPrompts[mood] ?? [];
    if (prompts.isEmpty) return "How are you feeling right now?";
    return prompts[(DateTime.now().millisecondsSinceEpoch % prompts.length)];
  }

  static MoodTheme getMoodTheme(MoodType mood) {
    switch (mood) {
      case MoodType.great:
        return MoodTheme(
          backgroundColor: '#FFF9E6', // Bright yellow tint
          primaryColor: '#FFD700',
          secondaryColor: '#FFA500',
          textColor: '#8B4513',
          recommendation: 'Gratitude Journal',
        );
      case MoodType.good:
        return MoodTheme(
          backgroundColor: '#E6F3FF', // Sky blue tint
          primaryColor: '#87CEEB',
          secondaryColor: '#4682B4',
          textColor: '#2F4F4F',
          recommendation: 'Affirmation of the Day',
        );
      case MoodType.okay:
        return MoodTheme(
          backgroundColor: '#F5F5DC', // Soft beige
          primaryColor: '#D2B48C',
          secondaryColor: '#BC9A6A',
          textColor: '#8B7355',
          recommendation: 'Breathing Session',
        );
      case MoodType.low:
        return MoodTheme(
          backgroundColor: '#F0F0F0', // Cool gray
          primaryColor: '#A9A9A9',
          secondaryColor: '#808080',
          textColor: '#2F2F2F',
          recommendation: 'Calm Meditation',
        );
      case MoodType.sad:
        return MoodTheme(
          backgroundColor: '#E6E6FA', // Deep navy with purple tint
          primaryColor: '#4B0082',
          secondaryColor: '#483D8B',
          textColor: '#2F2F4F',
          recommendation: 'Compassion Talk',
        );
    }
  }

  static Future<void> playMoodSound(MoodType mood) async {
    try {
      final player = AudioPlayer();
      
      switch (mood) {
        case MoodType.great:
          await player.play(AssetSource('sounds/nature/birds_chirping.mp3'));
          break;
        case MoodType.good:
          await player.play(AssetSource('sounds/ambient/gentle_chimes.mp3'));
          break;
        case MoodType.okay:
          await player.play(AssetSource('sounds/nature/soft_wind.mp3'));
          break;
        case MoodType.low:
          await player.play(AssetSource('sounds/nature/rain.mp3'));
          break;
        case MoodType.sad:
          await player.play(AssetSource('sounds/ambient/healing_tones.mp3'));
          break;
      }
    } catch (e) {
      // Handle audio playback error silently
      debugPrint('Failed to play mood sound: $e');
    }
  }

  static Color getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.great:
        return const Color(0xFFFFD700); // Gold
      case MoodType.good:
        return const Color(0xFF87CEEB); // Sky Blue
      case MoodType.okay:
        return const Color(0xFFD2B48C); // Tan
      case MoodType.low:
        return const Color(0xFFA9A9A9); // Dark Gray
      case MoodType.sad:
        return const Color(0xFF4B0082); // Indigo
    }
  }

  static List<Color> getMoodGradient(MoodType mood) {
    switch (mood) {
      case MoodType.great:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFFFF8C00),
        ];
      case MoodType.good:
        return [
          const Color(0xFF87CEEB),
          const Color(0xFF4682B4),
          const Color(0xFF1E90FF),
        ];
      case MoodType.okay:
        return [
          const Color(0xFFD2B48C),
          const Color(0xFFBC9A6A),
          const Color(0xFFA0826D),
        ];
      case MoodType.low:
        return [
          const Color(0xFFA9A9A9),
          const Color(0xFF808080),
          const Color(0xFF696969),
        ];
      case MoodType.sad:
        return [
          const Color(0xFF4B0082),
          const Color(0xFF483D8B),
          const Color(0xFF6A5ACD),
        ];
    }
  }

  // Check if user has had persistent sad mood
  static bool shouldShowMentalHealthResources(List<MoodEntry> recentEntries) {
    if (recentEntries.length < 3) return false;
    
    int consecutiveSadDays = 0;
    for (final entry in recentEntries.take(3)) {
      if (entry.mood == MoodType.sad) {
        consecutiveSadDays++;
      } else {
        break;
      }
    }
    
    return consecutiveSadDays >= 3;
  }

  // Generate proactive notifications based on mood patterns
  static String? generateProactiveMessage(
    MoodType? todaysMood,
    List<MoodEntry> weekHistory,
  ) {
    if (weekHistory.isEmpty) return null;
    
    // Check for patterns
    final mondayMoods = weekHistory
        .where((e) => e.timestamp.weekday == DateTime.monday)
        .map((e) => e.mood)
        .toList();
    
    if (mondayMoods.length >= 2 && mondayMoods.every((m) => m == MoodType.low)) {
      return "Mondays seem tough for you. Would you like to set up a Monday motivation routine? 💪";
    }
    
    final fridayMoods = weekHistory
        .where((e) => e.timestamp.weekday == DateTime.friday)
        .map((e) => e.mood)
        .toList();
    
    if (fridayMoods.length >= 2 && fridayMoods.every((m) => m == MoodType.great)) {
      return "Fridays bring you joy! Let's capture what makes Fridays special for you. ✨";
    }
    
    return null;
  }
}