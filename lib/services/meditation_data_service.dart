import '../models/meditation_models.dart';

class MeditationDataService {
  
  // Free Guided Meditation Sessions
  static List<MeditationSession> getFreeMeditationSessions() {
    return [
      MeditationSession(
        id: '1',
        title: 'Stress Relief Meditation',
        duration: '10 min',
        description: 'Release tension and find inner calm with this gentle guided meditation',
        difficulty: 'Beginner',
        category: 'Stress Relief',
        audioUrl: 'tts_stress_relief', // Will use TTS
        imageUrl: 'assets/meditation/stress.png',
        instructor: 'AI Guide',
        tags: ['stress', 'relaxation', 'calm'],
      ),
      MeditationSession(
        id: '2',
        title: 'Anxiety Relief',
        duration: '15 min',
        description: 'Gentle guidance to ease anxiety and restore peace of mind',
        difficulty: 'Beginner',
        category: 'Anxiety',
        audioUrl: 'tts_anxiety_relief',
        imageUrl: 'assets/meditation/anxiety.png',
        instructor: 'AI Guide',
        tags: ['anxiety', 'peace', 'comfort'],
      ),
      MeditationSession(
        id: '3',
        title: 'Focus & Concentration',
        duration: '20 min',
        description: 'Enhance mental clarity and improve concentration power',
        difficulty: 'Intermediate',
        category: 'Focus',
        audioUrl: 'tts_focus_meditation',
        imageUrl: 'assets/meditation/focus.png',
        instructor: 'AI Guide',
        tags: ['focus', 'concentration', 'clarity'],
      ),
      MeditationSession(
        id: '4',
        title: 'Sleep Preparation',
        duration: '25 min',
        description: 'Prepare your mind and body for restful, deep sleep',
        difficulty: 'Beginner',
        category: 'Sleep',
        audioUrl: 'tts_sleep_meditation',
        imageUrl: 'assets/meditation/sleep.png',
        instructor: 'AI Guide',
        tags: ['sleep', 'rest', 'bedtime'],
      ),
      MeditationSession(
        id: '5',
        title: 'Body Scan Relaxation',
        duration: '30 min',
        description: 'Progressive muscle relaxation for complete physical tension release',
        difficulty: 'Intermediate',
        category: 'Relaxation',
        audioUrl: 'tts_body_scan',
        imageUrl: 'assets/meditation/body_scan.png',
        instructor: 'AI Guide',
        tags: ['body scan', 'relaxation', 'tension'],
      ),
      MeditationSession(
        id: '6',
        title: 'Self-Compassion',
        duration: '18 min',
        description: 'Cultivate kindness and compassion towards yourself',
        difficulty: 'Intermediate',
        category: 'Emotional',
        audioUrl: 'tts_self_compassion',
        imageUrl: 'assets/meditation/compassion.png',
        instructor: 'AI Guide',
        tags: ['self-love', 'compassion', 'emotional'],
      ),
      MeditationSession(
        id: '7',
        title: 'Morning Mindfulness',
        duration: '12 min',
        description: 'Start your day with intention and peaceful awareness',
        difficulty: 'Beginner',
        category: 'Mindfulness',
        audioUrl: 'tts_morning_mindfulness',
        imageUrl: 'assets/meditation/morning.png',
        instructor: 'AI Guide',
        tags: ['morning', 'mindfulness', 'awareness'],
      ),
      MeditationSession(
        id: '8',
        title: 'Gratitude Practice',
        duration: '15 min',
        description: 'Cultivate appreciation and positive emotions through gratitude',
        difficulty: 'Beginner',
        category: 'Emotional',
        audioUrl: 'tts_gratitude',
        imageUrl: 'assets/meditation/gratitude.png',
        instructor: 'AI Guide',
        tags: ['gratitude', 'appreciation', 'positive'],
      ),
    ];
  }

  // Breathing Patterns
  static List<BreathingPattern> getBreathingPatterns() {
    return [
      BreathingPattern(
        name: '4-7-8 Relaxation',
        description: 'Dr. Andrew Weil\'s famous relaxation technique',
        inhale: 4,
        hold: 7,
        exhale: 8,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Box Breathing',
        description: 'Navy SEAL technique for stress and focus',
        inhale: 4,
        hold: 4,
        exhale: 4,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Simple 4-4',
        description: 'Easy breathing for beginners',
        inhale: 4,
        hold: 0,
        exhale: 4,
        difficulty: 'Beginner',
      ),
      BreathingPattern(
        name: 'Coherent Breathing',
        description: 'Heart-brain coherence technique',
        inhale: 5,
        hold: 0,
        exhale: 5,
        difficulty: 'Intermediate',
      ),
      BreathingPattern(
        name: 'Energizing Breath',
        description: 'Quick energizing technique',
        inhale: 2,
        hold: 2,
        exhale: 2,
        difficulty: 'Advanced',
      ),
    ];
  }

  // Nature Sounds and Ambient Audio
  static List<SoundCategory> getSoundCategories() {
    return [
      SoundCategory(
        name: 'Nature Sounds',
        description: 'Calming sounds from nature',
        icon: '🌿',
        tracks: [
          SoundTrack(
            id: 'rain',
            name: 'Gentle Rain',
            url: 'rain_sound', // Placeholder - would use real audio
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'ocean',
            name: 'Ocean Waves',
            url: 'ocean_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'forest',
            name: 'Forest Birds',
            url: 'forest_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'thunder',
            name: 'Distant Thunder',
            url: 'thunder_sound',
            duration: 'Continuous',
          ),
        ],
      ),
      SoundCategory(
        name: 'White Noise',
        description: 'Consistent background sounds',
        icon: '🔊',
        tracks: [
          SoundTrack(
            id: 'white_noise',
            name: 'Pure White Noise',
            url: 'white_noise_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'pink_noise',
            name: 'Pink Noise',
            url: 'pink_noise_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'brown_noise',
            name: 'Brown Noise',
            url: 'brown_noise_sound',
            duration: 'Continuous',
          ),
        ],
      ),
      SoundCategory(
        name: 'Instrumental',
        description: 'Peaceful instrumental music',
        icon: '🎵',
        tracks: [
          SoundTrack(
            id: 'piano',
            name: 'Soft Piano',
            url: 'piano_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'flute',
            name: 'Bamboo Flute',
            url: 'flute_sound',
            duration: 'Continuous',
          ),
          SoundTrack(
            id: 'bells',
            name: 'Tibetan Bells',
            url: 'bells_sound',
            duration: 'Continuous',
          ),
        ],
      ),
    ];
  }

  // Meditation Scripts for TTS
  static Map<String, String> getMeditationScripts() {
    return {
      'tts_stress_relief': '''
        Welcome to this stress relief meditation. Find a comfortable position and close your eyes.
        
        Take a deep breath in through your nose... and slowly exhale through your mouth.
        
        Allow your shoulders to drop and relax. Notice the weight of your body settling into your seat.
        
        Now, bring your attention to your breath. Don't try to change it, just observe.
        
        With each exhale, imagine releasing any tension or stress you've been carrying.
        
        Continue breathing naturally, letting go of worries with each out-breath.
        
        You are safe. You are calm. You are at peace.
        
        Take three more deep breaths, and when you're ready, gently open your eyes.
      ''',
      
      'tts_anxiety_relief': '''
        This is a safe space for you to relax and find peace. Close your eyes and breathe naturally.
        
        Place one hand on your chest and one on your belly. Feel the gentle rise and fall.
        
        Anxiety is temporary. It will pass. You are stronger than your worries.
        
        Breathe in calm... breathe out fear. Breathe in peace... breathe out anxiety.
        
        Imagine a warm, golden light surrounding you, protecting you from all harm.
        
        You are grounded. You are present. You are safe in this moment.
        
        Let this feeling of calm fill every cell of your body.
        
        When you're ready, take a deep breath and slowly open your eyes.
      ''',
      
      'tts_focus_meditation': '''
        Welcome to this focus meditation. Sit comfortably with your spine straight.
        
        Close your eyes and take three deep breaths to center yourself.
        
        Now, bring your attention to a single point - your breath at the tip of your nose.
        
        When your mind wanders, and it will, gently bring it back to your breath.
        
        This is training for your mind. Each time you return to focus, you grow stronger.
        
        Continue this practice, breathing naturally and maintaining focus.
        
        Your mind is becoming clearer, sharper, more focused with each breath.
        
        When you're ready, bring this enhanced focus into your day.
      ''',
      
      'tts_sleep_meditation': '''
        It's time to prepare for restful sleep. Lie down comfortably and close your eyes.
        
        Let your whole body sink into your bed. Feel supported and safe.
        
        Starting from your toes, tense and then relax each part of your body.
        
        Your legs are heavy and relaxed... your arms are loose and comfortable.
        
        Your mind is quiet now. The day is done. It's time to rest.
        
        Breathe slowly and deeply. With each breath, you become more drowsy.
        
        Let sleep come naturally. You are safe to rest and restore.
        
        Drift peacefully into deep, healing sleep.
      ''',
    };
  }
}