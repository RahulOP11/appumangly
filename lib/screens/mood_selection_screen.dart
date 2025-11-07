import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_models.dart';
import '../services/mood_analytics_service.dart';
import '../services/mood_response_handler.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({super.key});

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen>
    with TickerProviderStateMixin {
  final MoodAnalyticsService _analyticsService = MoodAnalyticsService();
  
  MoodType? selectedMood;
  bool isSubmitting = false;
  late AnimationController _backgroundController;
  late AnimationController _buttonController;
  late AnimationController _responseController;
  
  MoodResponse? currentResponse;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _responseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _checkTodaysMood();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _buttonController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _checkTodaysMood() async {
    final hasLogged = await _analyticsService.hasMoodLoggedToday();
    if (hasLogged && mounted) {
      final todaysMood = await _analyticsService.getTodaysMood();
      if (todaysMood != null) {
        setState(() {
          selectedMood = todaysMood;
          currentResponse = MoodResponseHandler.getMoodResponse(todaysMood);
        });
        _responseController.forward();
      }
    }
  }

  Future<void> _onMoodSelected(MoodType mood) async {
    if (isSubmitting) return;
    
    setState(() {
      selectedMood = mood;
      isSubmitting = true;
    });

    await _buttonController.forward();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Save mood to Firestore
        await _analyticsService.logMoodEntry(
          userId: user.uid,
          mood: mood,
          source: 'mood_selection_screen',
        );

        // Get mood response
        final response = MoodResponseHandler.getMoodResponse(mood);
        
        // Play mood sound
        MoodResponseHandler.playMoodSound(mood);
        
        setState(() {
          currentResponse = response;
          isSubmitting = false;
        });
        
        await _responseController.forward();
        
        // Navigate back to home with result after showing response
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context, mood);
          }
        });
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save mood: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: currentResponse != null
                    ? MoodResponseHandler.getMoodGradient(currentResponse!.mood)
                    : [
                        Colors.purple.shade200,
                        Colors.blue.shade200,
                        Colors.teal.shade200,
                      ],
                stops: [
                  0.0,
                  0.5 + 0.3 * _backgroundController.value,
                  1.0,
                ],
              ),
            ),
            child: SafeArea(
              child: currentResponse != null
                  ? _buildMoodResponse()
                  : _buildMoodSelection(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
            ],
          ),
          
          const Spacer(),
          
          // Title
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Select the option that best describes your current mood',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Mood buttons
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: MoodType.values.map((mood) {
                return _buildMoodButton(mood);
              }).toList(),
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMoodButton(MoodType mood) {
    final isSelected = selectedMood == mood;
    
    return GestureDetector(
      onTap: () => _onMoodSelected(mood),
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          final scale = isSelected ? 1.0 - 0.1 * _buttonController.value : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isSelected ? 0.9 : 0.7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? MoodResponseHandler.getMoodColor(mood).withOpacity(0.4)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isSelected ? 12 : 8,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isSelected
                    ? Border.all(
                        color: MoodResponseHandler.getMoodColor(mood),
                        width: 3,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    mood.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Label
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? MoodResponseHandler.getMoodColor(mood)
                          : Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category
                  Text(
                    mood.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodResponse() {
    if (currentResponse == null) return const SizedBox.shrink();
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _responseController,
        curve: Curves.elasticOut,
      )),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context, selectedMood),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
              ],
            ),
            
            const Spacer(),
            
            // Mood confirmation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Selected mood display
                  Text(
                    selectedMood!.emoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'You\'re feeling ${selectedMood!.label}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Response message
                  Text(
                    currentResponse!.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  ...currentResponse!.actions.take(2).map((action) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleMoodAction(action),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MoodResponseHandler.getMoodColor(selectedMood!),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            action.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Return to home button
            TextButton(
              onPressed: () => Navigator.pop(context, selectedMood),
              child: const Text(
                'Return to Home',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMoodAction(MoodAction action) {
    switch (action.type) {
      case MoodActionType.journal:
        _showJournalDialog(action.description);
        break;
      case MoodActionType.meditation:
        _showMeditationOptions(action.data);
        break;
      case MoodActionType.breathing:
        _showBreathingExercise(action.data);
        break;
      case MoodActionType.gratitude:
        _showGratitudeCard(action.data?['prompt']);
        break;
      case MoodActionType.affirmation:
        _showAffirmation(action.description);
        break;
      default:
        _showComingSoon(action.title);
    }
  }

  void _showJournalDialog(String prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Journal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prompt),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Journal entry saved! 📝')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMeditationOptions(Map<String, dynamic>? data) {
    final duration = data?['duration'] ?? 5;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧘 Meditation'),
        content: Text('Ready for a $duration-minute meditation session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to meditation screen
              Navigator.pushNamed(context, '/meditation');
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showBreathingExercise(Map<String, dynamic>? data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌬️ Breathing Exercise'),
        content: const Text('Let\'s do a simple breathing exercise together.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Start breathing exercise
              _startBreathingExercise();
            },
            child: const Text('Begin'),
          ),
        ],
      ),
    );
  }

  void _showGratitudeCard(String? prompt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌸 Gratitude'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prompt ?? 'What are you grateful for today?'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'I\'m grateful for...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gratitude saved! 🙏')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAffirmation(String affirmation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: MoodResponseHandler.getMoodGradient(selectedMood!),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✨',
                style: TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 16),
              Text(
                affirmation,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: selectedMood != null 
                      ? MoodResponseHandler.getMoodColor(selectedMood!)
                      : Colors.purple,
                ),
                child: const Text('Thank you'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startBreathingExercise() {
    // Simple breathing exercise implementation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _BreathingExerciseDialog(),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon! 🚀'),
        backgroundColor: Colors.orange.shade400,
      ),
    );
  }
}

class _BreathingExerciseDialog extends StatefulWidget {
  const _BreathingExerciseDialog();

  @override
  State<_BreathingExerciseDialog> createState() => _BreathingExerciseDialogState();
}

class _BreathingExerciseDialogState extends State<_BreathingExerciseDialog>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  
  int currentCycle = 0;
  final int totalCycles = 5;
  String currentPhase = 'Breathe In';

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    
    _startBreathingCycle();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _startBreathingCycle() {
    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentPhase = 'Breathe Out';
        });
        _breathController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          currentCycle++;
          currentPhase = 'Breathe In';
        });
        
        if (currentCycle < totalCycles) {
          _breathController.forward();
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Great job! Breathing exercise complete. 🌬️')),
          );
        }
      }
    });
    
    _breathController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Breathing Exercise',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blue.shade200,
                          Colors.blue.shade400,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Text(
              currentPhase,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Cycle ${currentCycle + 1} of $totalCycles',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Stop'),
            ),
          ],
        ),
      ),
    );
  }
}