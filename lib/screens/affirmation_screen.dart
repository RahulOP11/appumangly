import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AffirmationScreen extends StatefulWidget {
  const AffirmationScreen({Key? key}) : super(key: key);

  @override
  _AffirmationScreenState createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Frequency audio files with their purposes
  final List<Map<String, dynamic>> _frequencyAudios = [
    {
      'title': 'Alpha Waves (8 Hz) - For Stress Relief',
      'subtitle': 'Calm your mind and reduce anxiety',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/100-binaurale-beats-pur-alpha-waves-8-hz-100-ohne-musik-200257.mp3',
      'category': 'Stress Relief',
      'frequency': '8 Hz',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.spa,
    },
    {
      'title': 'Beta Waves (14 Hz) - For Clear Thoughts',
      'subtitle': 'Enhance focus and mental clarity',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/100-binaurale-beats-pur-beta-waves-14-hz-100-ohne-musik-200266.mp3',
      'category': 'Mental Clarity',
      'frequency': '14 Hz',
      'color': const Color(0xFF2196F3),
      'icon': Icons.psychology,
    },
    {
      'title': 'Theta Waves (4 Hz) - Restart Your Brain',
      'subtitle': 'Deep relaxation and brain reset',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/binaural-beats-theta-waves-4-hz-60205.mp3',
      'category': 'Brain Reset',
      'frequency': '4 Hz',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.refresh,
    },
    {
      'title': 'Delta Waves (0.5 Hz) - Deep Sleep',
      'subtitle': 'For deep healing sleep',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/binaural-beats_delta_440_440-5hz-48565.mp3',
      'category': 'Sleep & Recovery',
      'frequency': '0.5 Hz',
      'color': const Color(0xFF3F51B5),
      'icon': Icons.bedtime,
    },
    {
      'title': '417 Hz - Remove Negative Energy',
      'subtitle': 'Clear negative thoughts and emotions',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/417hz-frequency-ambient-music-meditationcalmingzenspiritual-music-293573.mp3',
      'category': 'Energy Clearing',
      'frequency': '417 Hz',
      'color': const Color(0xFFFF9800),
      'icon': Icons.cleaning_services,
    },
    {
      'title': '852 Hz - Spiritual Awareness',
      'subtitle': 'Enhance intuition and spiritual connection',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/852hz-frequency-ambient-music-meditationcalmingzenspiritual-music-311556.mp3',
      'category': 'Spiritual Growth',
      'frequency': '852 Hz',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.self_improvement,
    },
    {
      'title': '963 Hz - Crown Chakra Activation',
      'subtitle': 'Connect with higher consciousness',
      'url': 'https://storage.googleapis.com/umangly-audio/audios/963hz-frequency-ambient-music-meditationcalmingzenspiritual-music-311563.mp3',
      'category': 'Higher Consciousness',
      'frequency': '963 Hz',
      'color': const Color(0xFF673AB7),
      'icon': Icons.auto_awesome,
    },
  ];

  // Daily affirmations
  final List<String> _dailyAffirmations = [
    "I am worthy of love and respect",
    "I choose peace over worry",
    "I am capable of amazing things",
    "I trust in my ability to overcome challenges",
    "I am grateful for this moment",
    "I radiate positivity and joy",
    "I am exactly where I need to be",
    "I choose to see the good in everything",
    "I am strong, brave, and beautiful",
    "I believe in myself and my dreams",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer!.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });

    _audioPlayer!.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url, String title) async {
    try {
      if (_currentlyPlayingUrl == url && _isPlaying) {
        await _audioPlayer!.pause();
      } else {
        if (_currentlyPlayingUrl != url) {
          await _audioPlayer!.stop();
        }
        await _audioPlayer!.play(UrlSource(url));
        setState(() {
          _currentlyPlayingUrl = url;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playing: $title'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildFrequencyCard(Map<String, dynamic> audio) {
    final isCurrentlyPlaying = _currentlyPlayingUrl == audio['url'] && _isPlaying;
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              audio['color'].withOpacity(0.1),
              audio['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: audio['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      audio['icon'],
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          audio['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          audio['subtitle'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: audio['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      audio['frequency'],
                      style: TextStyle(
                        color: audio['color'],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _playAudio(audio['url'], audio['title']),
                    icon: Icon(
                      isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(isCurrentlyPlaying ? 'Pause' : 'Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: audio['color'],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              if (isCurrentlyPlaying && _totalDuration.inSeconds > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(_formatDuration(_currentPosition)),
                    Expanded(
                      child: Slider(
                        value: _currentPosition.inSeconds.toDouble(),
                        max: _totalDuration.inSeconds.toDouble(),
                        onChanged: (value) {
                          _audioPlayer!.seek(Duration(seconds: value.toInt()));
                        },
                        activeColor: audio['color'],
                      ),
                    ),
                    Text(_formatDuration(_totalDuration)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyAffirmationCard() {
    final today = DateTime.now();
    final affirmation = _dailyAffirmations[today.day % _dailyAffirmations.length];
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Today\'s Affirmation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '"$affirmation"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Affirmations'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Daily Affirmations'),
            Tab(text: 'Healing Frequencies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Daily Affirmations Tab
          SingleChildScrollView(
            child: Column(
              children: [
                _buildDailyAffirmationCard(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'More Affirmations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _dailyAffirmations.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.format_quote, color: Color(0xFF667eea)),
                        title: Text(_dailyAffirmations[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () {
                            // TODO: Add to favorites
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Healing Frequencies Tab
          SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Enhance Your Mood with Frequencies',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Listen to specific frequencies to improve your mental state',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _frequencyAudios.length,
                  itemBuilder: (context, index) {
                    return _buildFrequencyCard(_frequencyAudios[index]);
                  },
                ),
                const SizedBox(height: 100), // Space for floating audio player
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _isPlaying
          ? FloatingActionButton(
              onPressed: () => _audioPlayer!.stop(),
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            )
          : null,
    );
  }
}