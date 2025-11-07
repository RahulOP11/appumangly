import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.4); // Slow, calm pace
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setPitch(1.0);

      // Set voice to a calm, soothing one if available
      var voices = await _flutterTts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        // Try to find a female voice as they tend to be more soothing
        var femaleVoice = voices.firstWhere(
          (voice) {
            String name = voice['name']?.toString().toLowerCase() ?? '';
            return name.contains('female') || 
                   name.contains('karen') || 
                   name.contains('samantha');
          },
          orElse: () => voices.first,
        );
        
        // Convert to Map<String, String> for compatibility
        Map<String, String> voiceMap = Map<String, String>.from(femaleVoice.cast<String, String>());
        await _flutterTts.setVoice(voiceMap);
      }

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  static Future<void> speakMeditationScript(String script) async {
    await initialize();
    
    try {
      // Clean the script for better TTS pronunciation
      String cleanScript = _cleanScriptForTTS(script);
      
      // Add pauses for meditation timing
      String pausedScript = _addMeditationPauses(cleanScript);
      
      await _flutterTts.speak(pausedScript);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('TTS pause error: $e');
    }
  }

  static Future<void> resume() async {
    try {
      // Flutter TTS doesn't have resume, so we'll need to handle this differently
      // This would require keeping track of position and restarting from there
    } catch (e) {
      print('TTS resume error: $e');
    }
  }

  static String _cleanScriptForTTS(String script) {
    return script
        .replaceAll('...', '. Pause.')
        .replaceAll('  ', ' ')
        .trim();
  }

  static String _addMeditationPauses(String script) {
    // Add SSML-like pauses for meditation rhythm
    return script
        .replaceAll('.', '. <break time="2s"/>')
        .replaceAll('Pause.', '<break time="5s"/>')
        .replaceAll('breathe in', '<prosody rate="slow">breathe in</prosody>')
        .replaceAll('breathe out', '<prosody rate="slow">breathe out</prosody>')
        .replaceAll('exhale', '<prosody rate="slow">exhale</prosody>');
  }

  // For breathing exercises
  static Future<void> speakBreathingInstruction(String instruction) async {
    await initialize();
    
    try {
      // Use slower, more deliberate speech for breathing
      await _flutterTts.setSpeechRate(0.3);
      await _flutterTts.speak(instruction);
      await _flutterTts.setSpeechRate(0.4); // Reset to normal meditation pace
    } catch (e) {
      print('TTS breathing instruction error: $e');
    }
  }

  // Get available voices for user preference
  static Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    await initialize();
    try {
      var voices = await _flutterTts.getVoices;
      return List<Map<String, dynamic>>.from(voices ?? []);
    } catch (e) {
      print('Get voices error: $e');
      return [];
    }
  }

  // Set custom voice
  static Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      print('Set voice error: $e');
    }
  }

  // Adjust speech settings
  static Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('Set speech rate error: $e');
    }
  }

  static Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print('Set volume error: $e');
    }
  }

  static Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('Set pitch error: $e');
    }
  }
}