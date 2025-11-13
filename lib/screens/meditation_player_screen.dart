import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/meditation_models.dart';
import '../services/meditation_data_service.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final MeditationSession session;

  const MeditationPlayerScreen({super.key, required this.session});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with SingleTickerProviderStateMixin {
  late FlutterTts _flutterTts;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  bool _isPlaying = false;
  bool _isLoading = false;
  int _currentStepIndex = 0;
  late List<String> _meditationSteps;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeAnimation();
    _loadMeditationContent();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.4);
    _flutterTts.setPitch(0.8);
    _flutterTts.setVolume(0.8);
    
    _flutterTts.setCompletionHandler(() {
      if (_currentStepIndex < _meditationSteps.length - 1) {
        _nextStep();
      } else {
        _stopMeditation();
      }
    });
  }

  void _initializeAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadMeditationContent() {
    final scripts = MeditationDataService.getMeditationScripts();
    final script = scripts[widget.session.audioUrl] ?? '';
    
    _meditationSteps = script
        .split('\n\n')
        .where((step) => step.trim().isNotEmpty)
        .map((step) => step.trim())
        .toList();
    
    if (_meditationSteps.isNotEmpty) {
      _currentText = _meditationSteps[0];
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _breathingController.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _flutterTts.pause();
      _breathingController.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isLoading = true);
      await _flutterTts.speak(_currentText);
      _breathingController.repeat(reverse: true);
      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });
    }
  }

  void _stopMeditation() {
    _flutterTts.stop();
    _breathingController.stop();
    setState(() {
      _isPlaying = false;
      _currentStepIndex = 0;
      if (_meditationSteps.isNotEmpty) {
        _currentText = _meditationSteps[0];
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _meditationSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _currentText = _meditationSteps[_currentStepIndex];
        _isPlaying = false;
      });
      _flutterTts.stop();
      _breathingController.stop();
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _currentText = _meditationSteps[_currentStepIndex];
        _isPlaying = false;
      });
      _flutterTts.stop();
      _breathingController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getCategoryColors(),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 5),
                      _buildBreathingCircle(),
                      const SizedBox(height: 15),
                      _buildSessionInfo(),
                      const SizedBox(height: 10),
                      _buildCurrentText(),
                      const SizedBox(height: 10),
                      _buildControls(),
                      const SizedBox(height: 8),
                      _buildStepIndicator(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.session.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _breathingAnimation,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Transform.scale(
            scale: _isPlaying ? _breathingAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      size: 25,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isPlaying ? 'Breathe' : 'Ready',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              widget.session.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(Icons.access_time, widget.session.duration),
                _buildInfoItem(Icons.person, widget.session.instructor),
                _buildInfoItem(Icons.signal_cellular_alt, widget.session.difficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 2),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentText() {
    return Expanded(
      flex: 2,
      child: Card(
        color: Colors.white.withOpacity(0.15),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${_currentStepIndex + 1} of ${_meditationSteps.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _currentText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentStepIndex > 0 ? _previousStep : null,
          icon: Icon(
            Icons.skip_previous,
            size: 28,
            color: _currentStepIndex > 0 ? Colors.white : Colors.white30,
          ),
        ),
        const SizedBox(width: 15),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(35),
              onTap: _togglePlayPause,
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Colors.grey[700],
                        strokeWidth: 2,
                      )
                    : Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                        color: Colors.grey[700],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        IconButton(
          onPressed: _stopMeditation,
          icon: const Icon(
            Icons.stop,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 15),
        IconButton(
          onPressed: _currentStepIndex < _meditationSteps.length - 1 ? _nextStep : null,
          icon: Icon(
            Icons.skip_next,
            size: 28,
            color: _currentStepIndex < _meditationSteps.length - 1 ? Colors.white : Colors.white30,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    if (_meditationSteps.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_meditationSteps.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentStepIndex 
                  ? Colors.white 
                  : Colors.white30,
            ),
          );
        }),
      ),
    );
  }

  List<Color> _getCategoryColors() {
    switch (widget.session.category) {
      case 'Stress Relief':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'Anxiety':
        return [const Color(0xFF48CAE4), const Color(0xFF0077B6)];
      case 'Focus':
        return [const Color(0xFF00B4DB), const Color(0xFF0083B0)];
      case 'Sleep':
        return [const Color(0xFF2D1B69), const Color(0xFF11998E)];
      case 'Relaxation':
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case 'Emotional':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'Mindfulness':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.session.category) {
      case 'Stress Relief':
        return Icons.spa;
      case 'Anxiety':
        return Icons.favorite;
      case 'Focus':
        return Icons.center_focus_strong;
      case 'Sleep':
        return Icons.nightlight_round;
      case 'Relaxation':
        return Icons.self_improvement;
      case 'Emotional':
        return Icons.mood;
      case 'Mindfulness':
        return Icons.psychology;
      default:
        return Icons.self_improvement;
    }
  }
}