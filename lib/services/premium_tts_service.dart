import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class PremiumTTSService {
  // Google Cloud Text-to-Speech API
  static const String _apiKey = 'AIzaSyCwIu9wwwo0Cn2M9iEqBMyhdu5DgZ_Fyy0'; // Replace with actual key
  static const String _baseUrl = 'https://texttospeech.googleapis.com/v1/text:synthesize';
  
  // Premium voice configurations
  static const Map<String, Map<String, dynamic>> _premiumVoices = {
    'meditation_female_calm': {
      'languageCode': 'en-US',
      'name': 'en-US-Journey-F',
      'ssmlGender': 'FEMALE',
      'description': 'Calm, soothing female voice perfect for meditation',
    },
    'meditation_male_deep': {
      'languageCode': 'en-US', 
      'name': 'en-US-Journey-M',
      'ssmlGender': 'MALE',
      'description': 'Deep, reassuring male voice for grounding meditations',
    },
    'breathing_female_gentle': {
      'languageCode': 'en-GB',
      'name': 'en-GB-Neural2-A',
      'ssmlGender': 'FEMALE',
      'description': 'Gentle British accent for breathing exercises',
    },
    'sleep_female_whisper': {
      'languageCode': 'en-US',
      'name': 'en-US-Studio-O',
      'ssmlGender': 'FEMALE',
      'description': 'Whisper-soft voice for sleep meditations',
    },
  };

  // Fallback to Flutter TTS
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure fallback TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.4);
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(0.9); // Slightly lower pitch for calm voice

      _isInitialized = true;
    } catch (e) {
      print('Premium TTS initialization error: $e');
    }
  }

  // Generate audio using Google Cloud TTS
  static Future<String?> generatePremiumAudio(
    String text, 
    String voiceType, 
    {double speakingRate = 0.75}
  ) async {
    try {
      final voice = _premiumVoices[voiceType];
      if (voice == null) return null;

      final requestBody = {
        'input': {'text': text},
        'voice': {
          'languageCode': voice['languageCode'],
          'name': voice['name'],
          'ssmlGender': voice['ssmlGender'],
        },
        'audioConfig': {
          'audioEncoding': 'MP3',
          'speakingRate': speakingRate,
          'pitch': 0.0,
          'volumeGainDb': 0.0,
          'effectsProfileId': ['telephony-class-application'],
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['audioContent']; // Base64 encoded audio
      }
    } catch (e) {
      print('Premium TTS generation error: $e');
    }
    return null;
  }

  // Speak with premium voice (with fallback)
  static Future<void> speakWithPremiumVoice(
    String text, 
    String voiceType,
    {bool useOnline = true}
  ) async {
    await initialize();

    if (useOnline && _apiKey != 'your_google_cloud_api_key') {
      try {
        String? audioContent = await generatePremiumAudio(text, voiceType);
        if (audioContent != null) {
          // In a real app, you'd decode and play the audio
          print('Playing premium voice audio: $voiceType');
          return;
        }
      } catch (e) {
        print('Premium voice failed, using fallback: $e');
      }
    }

    // Fallback to Flutter TTS with optimized settings
    await _speakWithOptimizedTTS(text, voiceType);
  }

  // Optimized Flutter TTS for different meditation types
  static Future<void> _speakWithOptimizedTTS(String text, String voiceType) async {
    try {
      // Adjust TTS settings based on voice type
      switch (voiceType) {
        case 'meditation_female_calm':
          await _flutterTts.setSpeechRate(0.4);
          await _flutterTts.setPitch(0.9);
          break;
        case 'meditation_male_deep':
          await _flutterTts.setSpeechRate(0.35);
          await _flutterTts.setPitch(0.7);
          break;
        case 'breathing_female_gentle':
          await _flutterTts.setSpeechRate(0.3);
          await _flutterTts.setPitch(1.0);
          break;
        case 'sleep_female_whisper':
          await _flutterTts.setSpeechRate(0.25);
          await _flutterTts.setPitch(0.8);
          await _flutterTts.setVolume(0.6);
          break;
      }

      // Add meditation-specific pauses and emphasis
      String enhancedText = _enhanceTextForMeditation(text);
      await _flutterTts.speak(enhancedText);
    } catch (e) {
      print('Optimized TTS error: $e');
    }
  }

  // Enhance text with SSML-like pauses for better meditation experience
  static String _enhanceTextForMeditation(String text) {
    return text
        .replaceAll('.', '... ') // Longer pauses at sentences
        .replaceAll(',', ', ') // Short pauses at commas
        .replaceAll('breathe in', '<emphasis level="moderate">breathe in</emphasis>')
        .replaceAll('breathe out', '<emphasis level="moderate">breathe out</emphasis>')
        .replaceAll('relax', '<prosody rate="slow">relax</prosody>')
        .replaceAll('calm', '<prosody rate="slow">calm</prosody>')
        .replaceAll('peace', '<prosody pitch="low">peace</prosody>');
  }

  // Get available premium voices
  static Map<String, String> getAvailablePremiumVoices() {
    return _premiumVoices.map((key, value) => 
        MapEntry(key, value['description'] as String));
  }

  // Stop current speech
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Premium TTS stop error: $e');
    }
  }

  // Create personalized meditation script
  static String createPersonalizedScript(
    String baseScript, 
    String userName, 
    String mood,
    int sessionLength
  ) {
    String personalizedIntro = 'Hello $userName, welcome to your $sessionLength minute meditation. ';
    
    String moodAdjustment = '';
    switch (mood.toLowerCase()) {
      case 'stressed':
        moodAdjustment = 'I can sense you may be feeling stressed today. Let\'s work together to find your inner calm. ';
        break;
      case 'anxious':
        moodAdjustment = 'It\'s natural to feel anxious sometimes. You are safe here, and we\'ll move through this together. ';
        break;
      case 'tired':
        moodAdjustment = 'You seem tired today. Let\'s focus on rest and gentle restoration. ';
        break;
      case 'excited':
        moodAdjustment = 'I can feel your positive energy today. Let\'s channel that into peaceful awareness. ';
        break;
      default:
        moodAdjustment = 'Take a moment to check in with yourself and notice how you\'re feeling right now. ';
    }

    return personalizedIntro + moodAdjustment + baseScript;
  }

  // Background music integration for meditation
  static const Map<String, String> _backgroundMusicStyles = {
    'zen': 'Soft Japanese flute with nature sounds',
    'tibetan': 'Tibetan singing bowls and gentle chimes',
    'nature': 'Pure nature sounds without music',
    'ambient': 'Ethereal ambient tones and pads',
    'silence': 'Complete silence for focused meditation',
  };

  static Map<String, String> getBackgroundMusicStyles() {
    return _backgroundMusicStyles;
  }
}