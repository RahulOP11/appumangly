import 'package:flutter/material.dart';
import 'dart:async';
import '../services/audio_service.dart';
import '../services/tts_service.dart';

class MeditationTimerScreen extends StatefulWidget {
  const MeditationTimerScreen({super.key});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen>
    with TickerProviderStateMixin {
  int _selectedMinutes = 5;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;
  String? _selectedBackgroundSound;
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final List<int> _timeOptions = [1, 3, 5, 10, 15, 20, 30, 45, 60];
  final List<Map<String, String>> _backgroundSounds = [
    {'id': 'none', 'name': 'Silent', 'icon': '🔕'},
    {'id': 'rain', 'name': 'Rain', 'icon': '🌧️'},
    {'id': 'ocean', 'name': 'Ocean', 'icon': '🌊'},
    {'id': 'forest', 'name': 'Forest', 'icon': '🌲'},
    {'id': 'piano', 'name': 'Piano', 'icon': '🎹'},
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _initAnimations();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: Duration(seconds: _selectedMinutes * 60),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    AudioService.stop();
    super.dispose();
  }

  void _startTimer() async {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _selectedMinutes * 60;
    });

    // Start background sound if selected
    if (_selectedBackgroundSound != null && _selectedBackgroundSound != 'none') {
      await AudioService.playAmbientSound(_selectedBackgroundSound!);
      await AudioService.setVolume(0.3);
    }

    // Start progress animation
    _progressController.duration = Duration(seconds: _remainingSeconds);
    _progressController.forward();

    // Announce start with properly formatted string (bypass SSML processing)
    String startMessage = 'Your ${_selectedMinutes.toString()} minute meditation session is beginning. Find a comfortable position and close your eyes.';
    await TTSService.speakSimple(startMessage);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _completeTimer();
      }
    });
  }

  void _completeTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    _progressController.reset();
    
    // Fade out background sound
    await AudioService.fadeOut();
    
    // Completion message with properly formatted string
    String completionMessage = 'Your meditation session is complete. Take a moment to notice how you feel. Well done.';
    await TTSService.speakSimple(completionMessage);
    
    _showCompletionDialog();
  }

  void _stopTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });

    _progressController.reset();
    await AudioService.stop();
    await TTSService.stop(); // Stop any ongoing TTS
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Session Complete!'),
        content: Text('You meditated for ${_selectedMinutes.toString()} minutes. Great job!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          if (!_isRunning) _buildTimeSelector(),
          if (!_isRunning) _buildBackgroundSoundSelector(),
          Expanded(
            child: _buildTimerDisplay(),
          ),
          _buildControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _timeOptions.length,
        itemBuilder: (context, index) {
          final minutes = _timeOptions[index];
          final isSelected = minutes == _selectedMinutes;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMinutes = minutes;
                _remainingSeconds = minutes * 60;
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$minutes',
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'min',
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackgroundSoundSelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _backgroundSounds.length,
        itemBuilder: (context, index) {
          final sound = _backgroundSounds[index];
          final isSelected = sound['id'] == _selectedBackgroundSound;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBackgroundSound = sound['id'];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sound['icon']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sound['name']!,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : Colors.white,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerDisplay() {
    final progress = _isRunning 
        ? 1.0 - (_remainingSeconds / (_selectedMinutes * 60))
        : 0.0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              // Timer circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRunning ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _isRunning ? 'Meditating...' : 'Ready to Start',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton.icon(
        onPressed: _isRunning ? _stopTimer : _startTimer,
        icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
        label: Text(_isRunning ? 'Stop' : 'Start'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF667eea),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}