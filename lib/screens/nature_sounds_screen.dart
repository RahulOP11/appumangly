import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../services/meditation_data_service.dart';
import '../services/audio_service.dart';
import '../services/freesound_api_service.dart';

class NatureSoundsScreen extends StatefulWidget {
  const NatureSoundsScreen({super.key});

  @override
  State<NatureSoundsScreen> createState() => _NatureSoundsScreenState();
}

class _NatureSoundsScreenState extends State<NatureSoundsScreen> {
  List<SoundCategory> _categories = [];
  List<Map<String, dynamic>> _natureSounds = [
    {
      'name': 'Ocean Waves',
      'description': 'Relaxing sounds of gentle ocean waves',
      'assetPath': 'assets/sounds/ocean_waves.mp3',
      'category': 'Ocean',
      'isPremium': false,
    },
    {
      'name': 'Forest Birds',
      'description': 'Peaceful forest ambiance with bird songs',
      'assetPath': 'assets/sounds/forest_birds.mp3',
      'category': 'Forest',
      'isPremium': false,
    },
    {
      'name': 'Gentle Rain',
      'description': 'Soothing rainfall sounds',
      'assetPath': 'assets/sounds/gentle_rain.mp3',
      'category': 'Rain',
      'isPremium': false,
    },
    {
      'name': 'Mountain Stream',
      'description': 'Crystal clear water flowing over rocks',
      'assetPath': 'assets/sounds/mountain_stream.mp3',
      'category': 'Water',
      'isPremium': true,
    },
    {
      'name': 'Thunderstorm',
      'description': 'Dramatic thunder and lightning',
      'assetPath': 'assets/sounds/thunderstorm.mp3',
      'category': 'Storm',
      'isPremium': true,
    },
  ];
  List<Map<String, dynamic>> _premiumSounds = [];
  
  String _selectedCategory = 'All';
  String? _currentlyPlaying;
  double _volume = 0.7;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSoundCategories();
    AudioService.initialize();
  }

  void _loadSoundCategories() {
    setState(() {
      _categories = MeditationDataService.getSoundCategories();
      _premiumSounds = FreesoundApiService.getPremiumNatureSounds();
    });
  }

  void _playSound(String soundId) async {
    if (_currentlyPlaying == soundId) {
      // Stop if already playing
      await AudioService.stop();
      setState(() {
        _currentlyPlaying = null;
      });
    } else {
      // Show loading indicator for premium sounds
      setState(() {
        _isLoading = true;
      });
      
      // Play new sound (now with real audio!)
      await AudioService.playAmbientSound(soundId);
      await AudioService.setVolume(_volume);
      setState(() {
        _currentlyPlaying = soundId;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildVolumeControl(),
          Expanded(
            child: _buildSoundCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volume_down,
            color: Colors.white,
          ),
          Expanded(
            child: Slider(
              value: _volume,
              onChanged: (value) async {
                setState(() {
                  _volume = value;
                });
                if (_currentlyPlaying != null) {
                  await AudioService.setVolume(_volume);
                }
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white.withOpacity(0.3),
            ),
          ),
          const Icon(
            Icons.volume_up,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCategories() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(SoundCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Text(
          category.icon,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Text(
          category.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        children: category.tracks.map((track) => _buildSoundTrack(track)).toList(),
      ),
    );
  }

  Widget _buildSoundTrack(SoundTrack track) {
    final isPlaying = _currentlyPlaying == track.id;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPlaying 
              ? const Color(0xFF667eea) 
              : Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.stop : Icons.play_arrow,
          color: isPlaying ? Colors.white : Colors.grey[600],
        ),
      ),
      title: Text(
        track.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isPlaying 
              ? const Color(0xFF667eea) 
              : const Color(0xFF2D3748),
        ),
      ),
      subtitle: Text(
        track.duration,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
      trailing: isPlaying 
          ? Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF667eea),
                ),
              ),
            )
          : null,
      onTap: () => _playSound(track.id),
    );
  }

  @override
  void dispose() {
    AudioService.stop();
    super.dispose();
  }
}