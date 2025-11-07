import 'package:flutter/material.dart';
import '../services/smile_rewards_service.dart';
import '../models/smile_models.dart';
import 'dart:async';
import 'dart:math';

class SimplifiedSmileBoostScreen extends StatefulWidget {
  const SimplifiedSmileBoostScreen({super.key});

  @override
  State<SimplifiedSmileBoostScreen> createState() => _SimplifiedSmileBoostScreenState();
}

class _SimplifiedSmileBoostScreenState extends State<SimplifiedSmileBoostScreen> 
    with TickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _smileAnimationController;
  late AnimationController _pointsAnimationController;
  late Animation<double> _smileScaleAnimation;
  late Animation<double> _pointsOpacityAnimation;

  // State variables
  bool _showRewardAnimation = false;
  List<SmileReward> _recentRewards = [];
  int _sessionPoints = 0;
  int _sessionSmiles = 0;
  bool _isSessionActive = false;
  String _motivationalMessage = '';
  Timer? _sessionTimer;
  DateTime? _sessionStartTime;
  int _consecutiveSmiles = 0;
  DateTime? _lastSmileTime;

  final List<String> _smileQuotes = [
    "A smile is the prettiest thing you can wear! 😊",
    "Smiling is contagious - spread the joy! ✨",
    "Your smile brightens someone's day! 🌟",
    "Happiness looks gorgeous on you! 💫",
    "Keep smiling, it suits you perfectly! 🎉",
    "A smile is a curve that sets everything straight! 😄",
    "Smile - it's the key that fits the lock of everybody's heart! 💖",
    "Life is better when you're laughing! 🌈",
    "Smiles are always in fashion! 👑",
    "Your smile is your superpower! ⚡",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setInitialMessage();
  }

  void _initializeAnimations() {
    _smileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _smileScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(
      parent: _smileAnimationController,
      curve: Curves.elasticOut,
    ));

    _pointsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pointsAnimationController,
      curve: Curves.bounceIn,
    ));
  }

  void _setInitialMessage() {
    setState(() {
      _motivationalMessage = "Ready to boost your mood? Let's spread some smiles! 🌟";
    });
  }

  void _startSmileSession() {
    setState(() {
      _isSessionActive = true;
      _sessionPoints = 0;
      _sessionSmiles = 0;
      _sessionStartTime = DateTime.now();
      _consecutiveSmiles = 0;
      _lastSmileTime = null;
      _motivationalMessage = _getRandomQuote();
    });

    // Start session timer for automatic encouragement
    _sessionTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_isSessionActive && mounted) {
        setState(() {
          _motivationalMessage = _getRandomQuote();
        });
      }
    });
  }

  void _stopSmileSession() {
    setState(() {
      _isSessionActive = false;
      _motivationalMessage = 'Session completed! You did amazing! 🎉';
    });
    
    _sessionTimer?.cancel();
    _showSessionSummary();
  }

  void _registerSmile() {
    if (!_isSessionActive) return;

    // Create smile detection result
    final now = DateTime.now();
    double confidence = _calculateSmileConfidence();
    
    // Check for consecutive smiles
    if (_lastSmileTime != null && now.difference(_lastSmileTime!).inSeconds < 5) {
      _consecutiveSmiles++;
    } else {
      _consecutiveSmiles = 1;
    }
    _lastSmileTime = now;

    final result = SmileDetectionResult(
      isSmiling: true,
      smileConfidence: confidence,
      timestamp: now,
      pointsEarned: _calculatePoints(confidence),
    );

    _onSmileDetected(result);
  }

  double _calculateSmileConfidence() {
    // Base confidence
    double confidence = 0.7 + (Random().nextDouble() * 0.3); // 0.7 to 1.0
    
    // Bonus for consecutive smiles
    if (_consecutiveSmiles > 1) {
      confidence += (_consecutiveSmiles * 0.05).clamp(0.0, 0.2);
    }
    
    // Session engagement bonus
    if (_sessionStartTime != null) {
      int sessionSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
      if (sessionSeconds > 30) confidence += 0.05; // Engaged bonus
    }
    
    return confidence.clamp(0.5, 1.0);
  }

  int _calculatePoints(double confidence) {
    int basePoints;
    
    if (confidence >= 0.9) basePoints = 12;
    else if (confidence >= 0.8) basePoints = 10;
    else if (confidence >= 0.7) basePoints = 8;
    else basePoints = 6;
    
    // Consecutive smile bonus
    int bonus = (_consecutiveSmiles ~/ 2).clamp(0, 5);
    
    return basePoints + bonus;
  }

  Future<void> _onSmileDetected(SmileDetectionResult result) async {
    final rewards = await SmileRewardsService.processSmileDetection(result);
    
    setState(() {
      _sessionPoints += result.pointsEarned;
      _sessionSmiles += 1;
      _motivationalMessage = _getSmileCompliment();
    });
    
    _smileAnimationController.forward().then((_) {
      _smileAnimationController.reverse();
    });

    if (rewards.isNotEmpty) {
      setState(() {
        _recentRewards.addAll(rewards);
        _showRewardAnimation = true;
        _sessionPoints += rewards.fold(0, (sum, reward) => sum + reward.points);
      });
      
      _pointsAnimationController.forward();
      
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showRewardAnimation = false;
          });
          _pointsAnimationController.reverse();
        }
      });
    }
  }

  String _getRandomQuote() {
    return _smileQuotes[Random().nextInt(_smileQuotes.length)];
  }

  String _getSmileCompliment() {
    final compliments = [
      "Beautiful smile! You're glowing! ✨",
      "Amazing! That smile is contagious! 🌟",
      "Perfect! You just made my day! 😊",
      "Wonderful! Keep spreading that joy! 💫",
      "Fantastic! That's the spirit! 🎉",
      "Incredible smile! You're a natural! 🌈",
      "Brilliant! Your positivity is shining! ⭐",
      "Magnificent! That smile is pure magic! 💖",
    ];
    return compliments[Random().nextInt(compliments.length)];
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('Session Complete!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wonderful session! Here\'s your happiness summary:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Smiles Shared', '$_sessionSmiles', '😊'),
              _buildSummaryRow('Joy Points Earned', '$_sessionPoints', '🏆'),
              _buildSummaryRow('Consecutive Smiles', '$_consecutiveSmiles', '🔥'),
              if (_recentRewards.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Rewards Earned:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ..._recentRewards.map((reward) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      Text(reward.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reward.title,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '+${reward.points}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return to dashboard with refresh flag
              },
              child: const Text('Back to Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _resetSession(); // Start new session
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
              ),
              child: const Text('New Session'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, String emoji) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF667eea),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSession() {
    setState(() {
      _sessionPoints = 0;
      _sessionSmiles = 0;
      _consecutiveSmiles = 0;
      _lastSmileTime = null;
      _recentRewards.clear();
      _showRewardAnimation = false;
    });
    
    _startSmileSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF667eea),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Smile Boost',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              // Session stats
              if (_isSessionActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('😊', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              '$_sessionSmiles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Smiles',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              '$_sessionPoints',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Points',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              '$_consecutiveSmiles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Streak',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Main smile button
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Motivational message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          _motivationalMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Main smile button
                      if (_isSessionActive)
                        AnimatedBuilder(
                          animation: _smileScaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _smileScaleAnimation.value,
                              child: GestureDetector(
                                onTap: _registerSmile,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '😊',
                                          style: TextStyle(fontSize: 80),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'TAP TO SMILE',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF667eea),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 40),

                      // Session controls
                      if (!_isSessionActive)
                        SizedBox(
                          width: 250,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _startSmileSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 10,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('🚀', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 10),
                                Text(
                                  'Start Smile Session',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _stopSmileSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'End Session',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Reward animation overlay
      floatingActionButton: _showRewardAnimation
          ? Center(
              child: AnimatedBuilder(
                animation: _pointsOpacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pointsOpacityAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.all(40),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _recentRewards.take(3).map((reward) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(reward.emoji, style: const TextStyle(fontSize: 40)),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reward.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '+${reward.points} joy points',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _smileAnimationController.dispose();
    _pointsAnimationController.dispose();
    super.dispose();
  }
}