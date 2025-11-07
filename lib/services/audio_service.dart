import 'package:audioplayers/audioplayers.dart';
import 'freesound_api_service.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentTrack;
  static bool _useOnlineContent = true;

  // Initialize audio service
  static Future<void> initialize() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop); // Loop ambient sounds
    } catch (e) {
      print('Audio service initialization error: $e');
    }
  }

  // Play nature sound or ambient track with real audio
  static Future<void> playAmbientSound(String soundId) async {
    try {
      await stop(); // Stop any current playback
      
      // Try to get real audio from Freesound API first
      if (_useOnlineContent) {
        String? onlineUrl = await _getOnlineAudioUrl(soundId);
        if (onlineUrl != null) {
          await _player.play(UrlSource(onlineUrl));
          _isPlaying = true;
          _currentTrack = soundId;
          return;
        }
      }
      
      // Fallback to local assets
      String audioPath = _getLocalAudioPath(soundId);
      await _player.play(AssetSource(audioPath));
      _isPlaying = true;
      _currentTrack = soundId;
    } catch (e) {
      print('Play ambient sound error: $e');
      // Ultimate fallback: generate simple tone or silence
      _playFallbackSound(soundId);
    }
  }

  // Get online audio URL from Freesound API
  static Future<String?> _getOnlineAudioUrl(String soundId) async {
    try {
      // Map our sound IDs to Freesound IDs
      Map<String, String> soundMapping = {
        'rain': '2523',           // High-quality rain sound
        'ocean': '32249',         // Ocean waves
        'forest': '15617',        // Forest birds
        'thunder': '1234',        // Distant thunder
        'white_noise': '58272',   // White noise generator
        'pink_noise': '22537',    // Pink noise
        'brown_noise': '18765',   // Brown noise
        'piano': '45123',         // Soft piano
        'flute': '28789',         // Bamboo flute
        'bells': '41529',         // Tibetan bells
      };

      String? freesoundId = soundMapping[soundId];
      if (freesoundId != null) {
        return await FreesoundApiService.getSoundDownloadUrl(freesoundId);
      }
    } catch (e) {
      print('Online audio URL error: $e');
    }
    return null;
  }

  // Play meditation background music
  static Future<void> playMeditationBackground(String trackId) async {
    try {
      await stop();
      
      String audioPath = _getMeditationBackgroundPath(trackId);
      await _player.play(AssetSource(audioPath));
      await _player.setVolume(0.3); // Lower volume for background
      _isPlaying = true;
      _currentTrack = trackId;
    } catch (e) {
      print('Play meditation background error: $e');
    }
  }

  // Stop current playback
  static Future<void> stop() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
        _currentTrack = null;
      }
    } catch (e) {
      print('Stop audio error: $e');
    }
  }

  // Pause current playback
  static Future<void> pause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        _isPlaying = false;
      }
    } catch (e) {
      print('Pause audio error: $e');
    }
  }

  // Resume playback
  static Future<void> resume() async {
    try {
      if (!_isPlaying && _currentTrack != null) {
        await _player.resume();
        _isPlaying = true;
      }
    } catch (e) {
      print('Resume audio error: $e');
    }
  }

  // Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Set volume error: $e');
    }
  }

  // Check if currently playing
  static bool get isPlaying => _isPlaying;
  
  // Get current track
  static String? get currentTrack => _currentTrack;

  // Private method to get local audio file paths (fallback)
  static String _getLocalAudioPath(String soundId) {
    // High-quality local audio files as fallback
    Map<String, String> soundPaths = {
      'rain': 'sounds/nature/rain_forest_hq.mp3',
      'ocean': 'sounds/nature/ocean_waves_malibu.mp3',
      'forest': 'sounds/nature/forest_birds_amazon.mp3',
      'thunder': 'sounds/nature/thunder_mountains.mp3',
      'white_noise': 'sounds/ambient/white_noise_premium.mp3',
      'pink_noise': 'sounds/ambient/pink_noise_studio.mp3',
      'brown_noise': 'sounds/ambient/brown_noise_deep.mp3',
      'piano': 'sounds/music/piano_meditation_soft.mp3',
      'flute': 'sounds/music/flute_bamboo_zen.mp3',
      'bells': 'sounds/music/tibetan_bells_authentic.mp3',
    };
    
    return soundPaths[soundId] ?? 'sounds/nature/silence.mp3';
  }

  static String _getMeditationBackgroundPath(String trackId) {
    Map<String, String> backgroundPaths = {
      'soft_piano': 'sounds/backgrounds/soft_piano.mp3',
      'nature_ambient': 'sounds/backgrounds/nature.mp3',
      'singing_bowls': 'sounds/backgrounds/singing_bowls.mp3',
      'om_chanting': 'sounds/backgrounds/om_chanting.mp3',
    };
    
    return backgroundPaths[trackId] ?? 'sounds/backgrounds/silence.mp3';
  }

  // Fallback for when audio files aren't available
  static void _playFallbackSound(String soundId) {
    print('Playing fallback sound for: $soundId');
    // In a real implementation, this could generate simple tones
    // or use online audio sources as fallback
  }

  // Dispose of audio resources
  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      print('Audio dispose error: $e');
    }
  }

  // Create audio session for meditation with background sound
  static Future<void> startMeditationSession({
    String? backgroundTrack,
    double backgroundVolume = 0.3,
  }) async {
    try {
      if (backgroundTrack != null) {
        await playMeditationBackground(backgroundTrack);
        await setVolume(backgroundVolume);
      }
    } catch (e) {
      print('Start meditation session error: $e');
    }
  }

  // Fade in audio
  static Future<void> fadeIn({
    Duration duration = const Duration(seconds: 3),
    double targetVolume = 1.0,
  }) async {
    try {
      await setVolume(0.0);
      
      const steps = 30;
      final stepDuration = duration.inMilliseconds ~/ steps;
      final volumeStep = targetVolume / steps;
      
      for (int i = 0; i <= steps; i++) {
        await setVolume(volumeStep * i);
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
    } catch (e) {
      print('Fade in error: $e');
    }
  }

  // Fade out audio
  static Future<void> fadeOut({
    Duration duration = const Duration(seconds: 3),
  }) async {
    try {
      const steps = 30;
      final stepDuration = duration.inMilliseconds ~/ steps;
      final currentVolume = 1.0; // Assume current volume is 1.0
      final volumeStep = currentVolume / steps;
      
      for (int i = steps; i >= 0; i--) {
        await setVolume(volumeStep * i);
        await Future.delayed(Duration(milliseconds: stepDuration));
      }
      
      await stop();
    } catch (e) {
      print('Fade out error: $e');
    }
  }
}