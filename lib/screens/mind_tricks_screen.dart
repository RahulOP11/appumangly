import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class MindTricksScreen extends StatefulWidget {
  const MindTricksScreen({Key? key}) : super(key: key);

  @override
  _MindTricksScreenState createState() => _MindTricksScreenState();
}

class _MindTricksScreenState extends State<MindTricksScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _videoController;
  Timer? _videoTimer;
  bool _isVideoPlaying = false;
  String? _currentVideoUrl;

  // Hypnotic videos for mind relaxation
  final List<Map<String, dynamic>> _hypnoticVideos = [
    {
      'title': 'Spiral Relaxation',
      'subtitle': 'Deep relaxation spiral pattern',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/151634-801075782_small.mp4',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.all_out,
    },
    {
      'title': 'Hypnotic Focus 1',
      'subtitle': 'Concentrate and let your mind drift',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/hypnotic13.mp4',
      'color': const Color(0xFF2196F3),
      'icon': Icons.visibility,
    },
    {
      'title': 'Hypnotic Focus 2',
      'subtitle': 'Visual meditation for stress relief',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/hypnotic18.mp4',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.center_focus_weak,
    },
    {
      'title': 'Hypnotic Focus 3',
      'subtitle': 'Calming visual patterns',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/hypnotic19.mp4',
      'color': const Color(0xFFFF9800),
      'icon': Icons.grain,
    },
    {
      'title': 'Hypnotic Focus 4',
      'subtitle': 'Deep focus and relaxation',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/hypnotic20.mp4',
      'color': const Color(0xFF673AB7),
      'icon': Icons.blur_circular,
    },
  ];

  // Optical illusion images for focus
  final List<Map<String, dynamic>> _illusionImages = [
    {
      'title': 'Optical Illusion Focus',
      'subtitle': 'Focus at the center and relax your eyes',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/optical-illusion-153444_1280.png',
      'color': const Color(0xFFE91E63),
      'icon': Icons.center_focus_strong,
      'instruction': 'Look at the center of this image for 30 seconds. Let your eyes relax and notice how the pattern seems to move.',
    },
    {
      'title': 'Abstract Mind Pattern',
      'subtitle': 'Geometric relaxation pattern',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/9698193.jpg',
      'color': const Color(0xFF3F51B5),
      'icon': Icons.all_inclusive,
      'instruction': 'Focus on the center point. Breathe slowly and let the patterns calm your mind.',
    },
    {
      'title': 'Starburst Meditation',
      'subtitle': 'Radial focus point for concentration',
      'url': 'https://storage.googleapis.com/umangly-audio/videos/starburst-5367319_1280.png',
      'color': const Color(0xFFFF5722),
      'icon': Icons.star,
      'instruction': 'Stare at the center of the starburst. Take deep breaths and let the radiating lines guide your focus inward.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _videoTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _playVideo(String url, String title) async {
    try {
      // Stop current video if playing
      if (_videoController != null) {
        await _videoController!.dispose();
      }
      _videoTimer?.cancel();

      // Initialize new video
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      setState(() {
        _isVideoPlaying = true;
        _currentVideoUrl = url;
      });

      // Play the video
      await _videoController!.play();

      // Show instruction dialog
      _showVideoInstructionDialog(title);

      // Auto-stop after 7 seconds
      _videoTimer = Timer(const Duration(seconds: 7), () {
        _stopVideo();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('7-second relaxation session completed! How do you feel?'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopVideo() {
    _videoController?.pause();
    _videoTimer?.cancel();
    setState(() {
      _isVideoPlaying = false;
      _currentVideoUrl = null;
    });
  }

  void _showVideoInstructionDialog(String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.visibility, color: Color(0xFF9C27B0)),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mind Relaxing Illusion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '🌟 Focus on the center of the screen\n'
                '🧘‍♀️ Breathe slowly and deeply\n'
                '✨ Let the patterns relax your mind\n'
                '⏰ Video will stop automatically after 7 seconds',
                textAlign: TextAlign.left,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  void _showImageFocusDialog(Map<String, dynamic> image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(image['icon'], color: image['color']),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        image['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: image['color'], width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      image['url'],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Image not available'),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: image['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Mind Relaxing Illusion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        image['instruction'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Done Focusing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: image['color'],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final isCurrentlyPlaying = _currentVideoUrl == video['url'] && _isVideoPlaying;
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              video['color'].withOpacity(0.1),
              video['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: video['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      video['icon'],
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
                          video['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          video['subtitle'],
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
              const SizedBox(height: 16),
              if (isCurrentlyPlaying && _videoController != null) ...[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: video['color'], width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _stopVideo,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: video['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '7 seconds for relaxation',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => _playVideo(video['url'], video['title']),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch (7 sec)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: video['color'],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(Map<String, dynamic> image) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              image['color'].withOpacity(0.1),
              image['color'].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: image['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      image['icon'],
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
                          image['title'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          image['subtitle'],
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
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: image['color'], width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    image['url'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Image not available'),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showImageFocusDialog(image),
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Focus on Center'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: image['color'],
                  foregroundColor: Colors.white,
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
        title: const Text('Mind Tricks'),
        backgroundColor: const Color(0xFF89f7fe),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Hypnotic Videos'),
            Tab(text: 'Focus Images'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Hypnotic Videos Tab
          SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Mind Relaxing Illusions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Watch these hypnotic patterns for 7 seconds to relax your mind',
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
                  itemCount: _hypnoticVideos.length,
                  itemBuilder: (context, index) {
                    return _buildVideoCard(_hypnoticVideos[index]);
                  },
                ),
              ],
            ),
          ),
          // Focus Images Tab
          SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Optical Illusion Focus',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Focus at the center of these images to calm your mind',
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
                  itemCount: _illusionImages.length,
                  itemBuilder: (context, index) {
                    return _buildImageCard(_illusionImages[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}