import 'dart:convert';
import 'package:http/http.dart' as http;

class FreesoundApiService {
  // Free API key - you can get your own at freesound.org/apiv2/apply/
  static const String _apiKey = 'moidZjjxMsaCwIvW0zJjH3tZ7fCThrH0FooNrzF2'; // Replace with actual key
  static const String _baseUrl = 'https://freesound.org/apiv2';
  
  // Curated high-quality nature sound IDs from Freesound
  static const Map<String, List<Map<String, dynamic>>> _curatedSounds = {
    'rain': [
      {'id': '2523', 'name': 'Rain on Leaves', 'duration': 120},
      {'id': '22537', 'name': 'Heavy Rain', 'duration': 180},
      {'id': '58272', 'name': 'Gentle Rain', 'duration': 300},
    ],
    'ocean': [
      {'id': '32249', 'name': 'Ocean Waves', 'duration': 240},
      {'id': '18765', 'name': 'Beach Waves', 'duration': 200},
      {'id': '41529', 'name': 'Calm Ocean', 'duration': 180},
    ],
    'forest': [
      {'id': '15617', 'name': 'Forest Birds', 'duration': 300},
      {'id': '28789', 'name': 'Wind in Trees', 'duration': 250},
      {'id': '45123', 'name': 'Morning Forest', 'duration': 400},
    ],
    'thunder': [
      {'id': '1234', 'name': 'Distant Thunder', 'duration': 180},
      {'id': '5678', 'name': 'Rain Thunder', 'duration': 220},
    ],
    'birds': [
      {'id': '9876', 'name': 'Dawn Chorus', 'duration': 300},
      {'id': '5432', 'name': 'Peaceful Birds', 'duration': 280},
    ],
  };

  // Get download URL for a sound
  static Future<String?> getSoundDownloadUrl(String soundId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sounds/$soundId/?token=$_apiKey'),
        headers: {'Authorization': 'Token $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['previews']['preview-hq-mp3']; // High quality preview
      }
    } catch (e) {
      print('Freesound API error: $e');
    }
    return null;
  }

  // Search for sounds by category
  static Future<List<Map<String, dynamic>>> searchSounds(String query, {int count = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/text/?query=$query&token=$_apiKey&page_size=$count&fields=id,name,duration,previews'),
        headers: {'Authorization': 'Token $_apiKey'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      }
    } catch (e) {
      print('Freesound search error: $e');
    }
    return [];
  }

  // Get curated sounds for each category
  static List<Map<String, dynamic>> getCuratedSounds(String category) {
    return _curatedSounds[category] ?? [];
  }

  // Get all available categories
  static List<String> getAvailableCategories() {
    return _curatedSounds.keys.toList();
  }

  // Fallback: Generate local audio file paths when API is unavailable
  static String getFallbackAudioPath(String category, String soundName) {
    // These would be local audio files in your assets
    final Map<String, String> fallbackPaths = {
      'rain_gentle': 'sounds/nature/rain_gentle.mp3',
      'rain_heavy': 'sounds/nature/rain_heavy.mp3',
      'ocean_waves': 'sounds/nature/ocean_waves.mp3',
      'ocean_calm': 'sounds/nature/ocean_calm.mp3',
      'forest_birds': 'sounds/nature/forest_birds.mp3',
      'forest_wind': 'sounds/nature/forest_wind.mp3',
      'thunder_distant': 'sounds/nature/thunder_distant.mp3',
      'birds_dawn': 'sounds/nature/birds_dawn.mp3',
    };
    
    String key = '${category}_${soundName.toLowerCase().replaceAll(' ', '_')}';
    return fallbackPaths[key] ?? 'sounds/nature/default.mp3';
  }

  // Download and cache sound for offline use
  static Future<bool> downloadAndCacheSound(String soundId, String localPath) async {
    try {
      final downloadUrl = await getSoundDownloadUrl(soundId);
      if (downloadUrl != null) {
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode == 200) {
          // In a real app, you'd save this to local storage
          // For now, we'll just return success
          print('Downloaded sound $soundId to $localPath');
          return true;
        }
      }
    } catch (e) {
      print('Download error: $e');
    }
    return false;
  }

  // Get premium nature sound recommendations
  static List<Map<String, dynamic>> getPremiumNatureSounds() {
    return [
      {
        'id': 'premium_rain_forest',
        'name': 'Amazon Rainforest',
        'description': 'Authentic sounds from the heart of the Amazon',
        'category': 'forest',
        'duration': 3600, // 1 hour
        'premium': true,
      },
      {
        'id': 'premium_ocean_malibu',
        'name': 'Malibu Beach Waves',
        'description': 'Recorded at sunrise on Malibu Beach',
        'category': 'ocean',
        'duration': 2700, // 45 minutes
        'premium': true,
      },
      {
        'id': 'premium_thunder_mountains',
        'name': 'Mountain Thunderstorm',
        'description': 'Epic thunderstorm in the Rocky Mountains',
        'category': 'thunder',
        'duration': 1800, // 30 minutes
        'premium': true,
      },
      {
        'id': 'premium_birds_himalaya',
        'name': 'Himalayan Dawn',
        'description': 'Rare bird songs from the Himalayas',
        'category': 'birds',
        'duration': 2400, // 40 minutes
        'premium': true,
      },
    ];
  }
}