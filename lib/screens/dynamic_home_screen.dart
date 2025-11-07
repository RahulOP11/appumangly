import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_models.dart';
import '../services/mood_analytics_service.dart';
import '../services/mood_response_handler.dart';
import 'mood_selection_screen.dart';

class DynamicHomePersonalization extends StatefulWidget {
  final Widget Function(BuildContext, MoodType?, WeeklyMoodSummary?) builder;
  
  const DynamicHomePersonalization({
    super.key,
    required this.builder,
  });

  @override
  State<DynamicHomePersonalization> createState() => _DynamicHomePersonalizationState();
}

class _DynamicHomePersonalizationState extends State<DynamicHomePersonalization>
    with TickerProviderStateMixin {
  final MoodAnalyticsService _analyticsService = MoodAnalyticsService();
  
  MoodType? currentMood;
  WeeklyMoodSummary? weeklyData;
  bool isLoading = true;
  
  late AnimationController _themeController;
  late AnimationController _cardController;

  @override
  void initState() {
    super.initState();
    
    _themeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _loadPersonalizationData();
  }

  @override
  void dispose() {
    _themeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalizationData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Get today's mood
      final todaysMood = await _analyticsService.getTodaysMood();
      
      // Get weekly summary
      final summary = await _analyticsService.generateWeeklySummary(
        userId: user.uid,
      );
      
      setState(() {
        currentMood = todaysMood;
        weeklyData = summary;
        isLoading = false;
      });
      
      _cardController.forward();
      if (currentMood != null) {
        _themeController.forward();
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading personalization data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return widget.builder(context, currentMood, weeklyData);
  }
}

class DynamicHomeScreen extends StatefulWidget {
  const DynamicHomeScreen({super.key});

  @override
  State<DynamicHomeScreen> createState() => _DynamicHomeScreenState();
}

class _DynamicHomeScreenState extends State<DynamicHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _welcomeController;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _welcomeController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: DynamicHomePersonalization(
        builder: (context, currentMood, weeklyData) {
          return AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                decoration: BoxDecoration(
                  gradient: _getBackgroundGradient(currentMood),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(user),
                        const SizedBox(height: 24),
                        _buildWelcomeCard(currentMood),
                        const SizedBox(height: 24),
                        _buildMoodStatusCard(currentMood),
                        const SizedBox(height: 24),
                        _buildRecommendationCard(currentMood),
                        if (weeklyData != null) ...[
                          const SizedBox(height: 24),
                          _buildWeeklySummaryCard(weeklyData),
                        ],
                        const SizedBox(height: 24),
                        _buildQuickActions(currentMood),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  LinearGradient _getBackgroundGradient(MoodType? mood) {
    if (mood == null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.indigo.shade100,
          Colors.blue.shade100,
          Colors.purple.shade100,
        ],
        stops: [
          0.0,
          0.5 + 0.3 * _backgroundController.value,
          1.0,
        ],
      );
    }
    
    final colors = MoodResponseHandler.getMoodGradient(mood);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors[0].withOpacity(0.3),
        colors[1].withOpacity(0.5),
        colors[2].withOpacity(0.7),
      ],
      stops: [
        0.0,
        0.5 + 0.2 * _backgroundController.value,
        1.0,
      ],
    );
  }

  Widget _buildHeader(User? user) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _welcomeController,
        curve: Curves.elasticOut,
      )),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Text(
                user?.displayName?.split(' ').first ?? 'Friend',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (user?.displayName?.isNotEmpty ?? false)
                  ? user!.displayName![0].toUpperCase()
                  : user?.email?[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(MoodType? mood) {
    return FadeTransition(
      opacity: _welcomeController,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Your Wellness Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mood != null
                  ? _getPersonalizedMessage(mood)
                  : 'Ready to check in with your emotions today?',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodStatusCard(MoodType? mood) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _welcomeController,
          curve: const Interval(0.3, 1.0),
        ),
      ),
      child: GestureDetector(
        onTap: () => _navigateToMoodSelection(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(mood != null ? 0.9 : 0.8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: mood != null
                    ? MoodResponseHandler.getMoodColor(mood).withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              if (mood != null) ...[
                Text(
                  mood.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  'Feeling ${mood.label}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MoodResponseHandler.getMoodColor(mood),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mood.category,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to log your mood',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(MoodType? mood) {
    if (mood == null) return const SizedBox.shrink();
    
    final theme = MoodResponseHandler.getMoodTheme(mood);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _welcomeController,
        curve: const Interval(0.5, 1.0),
      )),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MoodResponseHandler.getMoodColor(mood).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: MoodResponseHandler.getMoodColor(mood),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Recommended for You',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              theme.recommendation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getRecommendationDescription(theme.recommendation),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleRecommendation(theme.recommendation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoodResponseHandler.getMoodColor(mood),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Try Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard(WeeklyMoodSummary? summary) {
    if (summary == null) return const SizedBox.shrink();
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _welcomeController,
          curve: const Interval(0.7, 1.0),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'This Week\'s Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summary.dominantMood != null) ...[
              Text(
                'Dominant mood: ${summary.dominantMood!.emoji} ${summary.dominantMood!.label}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Total entries: ${summary.totalEntries}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mood stability: ${(summary.moodStability * 100).toInt()}%',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            if (summary.insights.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                summary.insights.first,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(MoodType? mood) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _welcomeController,
          curve: const Interval(0.8, 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.mood,
              label: 'Log Mood',
              color: mood != null 
                  ? MoodResponseHandler.getMoodColor(mood)
                  : Colors.purple,
              onTap: _navigateToMoodSelection,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.spa,
              label: 'Meditate',
              color: Colors.teal,
              onTap: () => Navigator.pushNamed(context, '/meditation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getPersonalizedMessage(MoodType mood) {
    switch (mood) {
      case MoodType.great:
        return 'Your positive energy is shining bright today! ✨';
      case MoodType.good:
        return 'You\'re in a good space today. Keep it up! 🌟';
      case MoodType.okay:
        return 'Today feels balanced. Let\'s see what we can explore together.';
      case MoodType.low:
        return 'Taking it one step at a time today. You\'re doing great. 💙';
      case MoodType.sad:
        return 'Sending you gentle support. You\'re not alone in this. 🤗';
    }
  }

  String _getRecommendationDescription(String recommendation) {
    switch (recommendation) {
      case 'Gratitude Journal':
        return 'Reflect on the positive moments and cultivate appreciation.';
      case 'Affirmation of the Day':
        return 'Start with positive self-talk to maintain your good energy.';
      case 'Breathing Session':
        return 'Center yourself with mindful breathing exercises.';
      case 'Calm Meditation':
        return 'Find peace and comfort through guided meditation.';
      case 'Compassion Talk':
        return 'Practice self-compassion and gentle understanding.';
      default:
        return 'Personalized activity based on your current mood.';
    }
  }

  void _handleRecommendation(String recommendation) {
    switch (recommendation) {
      case 'Gratitude Journal':
        _showGratitudeJournal();
        break;
      case 'Affirmation of the Day':
        _showDailyAffirmation();
        break;
      case 'Breathing Session':
        _startBreathingSession();
        break;
      case 'Calm Meditation':
      case 'Compassion Talk':
        Navigator.pushNamed(context, '/meditation');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$recommendation - Coming Soon! 🚀')),
        );
    }
  }

  void _showGratitudeJournal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🙏 Gratitude Journal'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('What are you grateful for today?'),
            SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'I\'m grateful for...',
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
                const SnackBar(content: Text('Gratitude saved! 🌟')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDailyAffirmation() {
    final affirmations = [
      'I am worthy of love and happiness',
      'I choose to focus on the positive',
      'I am grateful for this moment',
      'I have the strength to overcome challenges',
      'I am exactly where I need to be',
    ];
    
    final affirmation = affirmations[DateTime.now().day % affirmations.length];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.blue],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              const Text(
                'Daily Affirmation',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                affirmation,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                ),
                child: const Text('Thank you'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startBreathingSession() {
    Navigator.pushNamed(context, '/breathing');
  }

  void _navigateToMoodSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MoodSelectionScreen(),
      ),
    );
    
    if (result != null && result is MoodType) {
      // Refresh the home screen with new mood
      setState(() {});
    }
  }
}