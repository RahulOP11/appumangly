import 'package:flutter/material.dart';
import 'dart:async';
import '../models/meditation_models.dart';
import '../services/meditation_data_service.dart';
import '../services/tts_service.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  List<BreathingPattern> _patterns = [];
  BreathingPattern? _selectedPattern;
  bool _isRunning = false;
  String _currentPhase = 'Tap to Start';
  int _currentCycle = 0;
  int _totalCycles = 0;
  Timer? _breathingTimer;
  
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  
  @override
  void initState() {
    super.initState();
    _loadPatterns();
    _initAnimation();
  }

  void _loadPatterns() {
    setState(() {
      _patterns = MeditationDataService.getBreathingPatterns();
      _selectedPattern = _patterns.first;
    });
  }

  void _initAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _startBreathingExercise() async {
    if (_selectedPattern == null) return;
    
    setState(() {
      _isRunning = true;
      _currentCycle = 0;
      _totalCycles = 10; // Default number of cycles
    });

    await TTSService.speakBreathingInstruction(
      'Let\'s begin the ${_selectedPattern!.name} breathing exercise. Follow the circle and my guidance.'
    );

    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    if (!_isRunning || _selectedPattern == null) return;

    final pattern = _selectedPattern!;
    int phaseIndex = 0;
    final phases = [
      {'name': 'Breathe In', 'duration': pattern.inhale},
      if (pattern.hold > 0) {'name': 'Hold', 'duration': pattern.hold},
      {'name': 'Breathe Out', 'duration': pattern.exhale},
    ];

    void runPhase() {
      if (!_isRunning || phaseIndex >= phases.length) {
        _currentCycle++;
        if (_currentCycle < _totalCycles) {
          Timer(const Duration(seconds: 1), _runBreathingCycle);
        } else {
          _stopBreathingExercise();
        }
        return;
      }

      final currentPhaseData = phases[phaseIndex];
      final phaseName = currentPhaseData['name'] as String;
      final duration = currentPhaseData['duration'] as int;

      setState(() {
        _currentPhase = phaseName;
      });

      // Animate breathing circle
      if (phaseName == 'Breathe In') {
        _breathingController.forward();
        TTSService.speakBreathingInstruction('Breathe in');
      } else if (phaseName == 'Breathe Out') {
        _breathingController.reverse();
        TTSService.speakBreathingInstruction('Breathe out');
      } else if (phaseName == 'Hold') {
        TTSService.speakBreathingInstruction('Hold');
      }

      _breathingTimer = Timer(Duration(seconds: duration), () {
        phaseIndex++;
        runPhase();
      });
    }

    runPhase();
  }

  void _stopBreathingExercise() async {
    setState(() {
      _isRunning = false;
      _currentPhase = 'Complete! Tap to Start';
      _currentCycle = 0;
    });

    _breathingTimer?.cancel();
    _breathingController.reset();
    
    await TTSService.speakBreathingInstruction(
      'Well done! You have completed the breathing exercise. Take a moment to notice how you feel.'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildPatternSelector(),
          Expanded(
            child: _buildBreathingCircle(),
          ),
          _buildControls(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPatternSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _patterns.length,
        itemBuilder: (context, index) {
          final pattern = _patterns[index];
          final isSelected = pattern == _selectedPattern;
          
          return GestureDetector(
            onTap: () {
              if (!_isRunning) {
                setState(() {
                  _selectedPattern = pattern;
                });
              }
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern.name,
                    style: TextStyle(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pattern.description,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.grey[600] 
                          : Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${pattern.inhale}',
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF667eea) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pattern.hold > 0 ? '-${pattern.hold}' : '',
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF667eea) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '-${pattern.exhale}',
                        style: TextStyle(
                          color: isSelected 
                              ? const Color(0xFF667eea) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Container(
                width: 200 + (100 * _breathingAnimation.value),
                height: 200 + (100 * _breathingAnimation.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.air,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            _currentPhase,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_isRunning) ...[
            const SizedBox(height: 10),
            Text(
              'Cycle $_currentCycle of $_totalCycles',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _isRunning ? _stopBreathingExercise : _startBreathingExercise,
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isRunning ? 'Stop' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
          if (!_isRunning)
            IconButton(
              onPressed: () => _showCycleSelector(),
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }

  void _showCycleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Number of Cycles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 10, 15, 20].map((cycles) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _totalCycles = cycles;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _totalCycles == cycles 
                        ? const Color(0xFF667eea) 
                        : Colors.grey[300],
                    foregroundColor: _totalCycles == cycles 
                        ? Colors.white 
                        : Colors.black,
                  ),
                  child: Text('$cycles'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}