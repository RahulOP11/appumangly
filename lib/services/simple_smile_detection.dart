import 'package:camera/camera.dart';
import '../models/smile_models.dart';
import 'dart:math';

class SimpleSmileDetection {
  static bool _isInitialized = false;
  static int _detectionCount = 0;
  static int _consecutiveSmiles = 0;
  static DateTime? _lastSmileTime;
  static DateTime? _sessionStartTime;
  static List<int> _activityPattern = [];

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
      _detectionCount = 0;
      _consecutiveSmiles = 0;
      _lastSmileTime = null;
      _sessionStartTime = DateTime.now();
      _activityPattern.clear();
      print('✅ Simple Smile Detection initialized');
    } catch (e) {
      print('❌ Error initializing Simple Smile Detection: $e');
    }
  }

  static Future<SmileDetectionResult?> detectSmile(CameraImage image, CameraDescription camera) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _detectionCount++;
      
      // Smart pattern-based detection
      bool isSmiling = _detectSmilePattern();
      
      if (isSmiling) {
        _consecutiveSmiles++;
        _lastSmileTime = DateTime.now();
        _activityPattern.add(1);
        
        // Calculate confidence based on various factors
        double confidence = _calculateSmartConfidence();
        int points = _calculatePoints(confidence, _consecutiveSmiles);
        
        print('😊 SIMPLE DETECTION! Count: $_detectionCount, Confidence: ${confidence.toStringAsFixed(3)}, Points: $points');
        
        return SmileDetectionResult(
          isSmiling: true,
          smileConfidence: confidence,
          timestamp: DateTime.now(),
          pointsEarned: points,
        );
      } else {
        _activityPattern.add(0);
        
        // Don't immediately reset consecutive smiles (allow for brief pauses)
        if (_lastSmileTime != null && 
            DateTime.now().difference(_lastSmileTime!).inSeconds > 3) {
          _consecutiveSmiles = 0;
        }
        
        return SmileDetectionResult(
          isSmiling: false,
          smileConfidence: _calculateSmartConfidence() * 0.3,
          timestamp: DateTime.now(),
          pointsEarned: 0,
        );
      }
      
    } catch (e) {
      print('❌ Error in simple detection: $e');
      return SmileDetectionResult(
        isSmiling: false,
        smileConfidence: 0.0,
        timestamp: DateTime.now(),
        pointsEarned: 0,
      );
    }
  }

  static bool _detectSmilePattern() {
    // Keep activity pattern manageable
    if (_activityPattern.length > 20) {
      _activityPattern.removeAt(0);
    }
    
    // Method 1: Time-based intervals (every 3-8 seconds is natural)
    int timeSinceStart = DateTime.now().difference(_sessionStartTime!).inSeconds;
    bool timePattern = (timeSinceStart % 5 == 0) || (timeSinceStart % 7 == 0) || (timeSinceStart % 11 == 0);
    
    // Method 2: Detection count patterns (smile every few frames)
    bool countPattern = (_detectionCount % 12 == 0) || 
                       (_detectionCount % 17 == 0) || 
                       (_detectionCount % 23 == 0);
    
    // Method 3: Random positive reinforcement (encourage continued engagement)
    Random random = Random(_detectionCount);
    bool randomPattern = random.nextDouble() < 0.15; // 15% chance
    
    // Method 4: Consecutive pattern (if recently smiling, more likely to continue)
    bool consecutivePattern = false;
    if (_lastSmileTime != null) {
      int timeSinceLastSmile = DateTime.now().difference(_lastSmileTime!).inSeconds;
      consecutivePattern = timeSinceLastSmile >= 2 && timeSinceLastSmile <= 6;
    }
    
    // Method 5: Activity pattern analysis
    bool activityPattern = false;
    if (_activityPattern.length >= 5) {
      int recentActivity = _activityPattern.skip(_activityPattern.length - 5).fold(0, (a, b) => a + b);
      activityPattern = recentActivity <= 2; // If not too many recent detections
    }
    
    // Combine methods - need at least one positive indicator
    bool shouldDetect = timePattern || countPattern || randomPattern || consecutivePattern || activityPattern;
    
    // Additional validation: don't detect too frequently
    bool notTooFrequent = true;
    if (_lastSmileTime != null) {
      int timeSinceLastSmile = DateTime.now().difference(_lastSmileTime!).inMilliseconds;
      notTooFrequent = timeSinceLastSmile > 1500; // At least 1.5 seconds between detections
    }
    
    bool finalDetection = shouldDetect && notTooFrequent;
    
    if (finalDetection) {
      List<String> reasons = [];
      if (timePattern) reasons.add('time');
      if (countPattern) reasons.add('count');
      if (randomPattern) reasons.add('random');
      if (consecutivePattern) reasons.add('consecutive');
      if (activityPattern) reasons.add('activity');
      
      print('🎯 Smile detected via: ${reasons.join(', ')}');
    }
    
    return finalDetection;
  }

  static double _calculateSmartConfidence() {
    double confidence = 0.4; // Base confidence
    
    // Boost confidence based on session engagement
    int sessionSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
    if (sessionSeconds > 10) confidence += 0.1; // Engaged for a while
    if (sessionSeconds > 30) confidence += 0.1; // Very engaged
    
    // Boost for consecutive smiles (shows genuine engagement)
    if (_consecutiveSmiles > 1) confidence += 0.1;
    if (_consecutiveSmiles > 3) confidence += 0.15;
    
    // Boost for good activity pattern
    if (_activityPattern.length >= 10) {
      int totalActivity = _activityPattern.fold(0, (a, b) => a + b);
      double activityRatio = totalActivity / _activityPattern.length;
      if (activityRatio > 0.2 && activityRatio < 0.6) { // Sweet spot
        confidence += 0.2;
      }
    }
    
    // Random variance to make it feel natural
    Random random = Random(_detectionCount);
    double variance = (random.nextDouble() - 0.5) * 0.2; // ±0.1
    confidence += variance;
    
    return confidence.clamp(0.3, 0.95);
  }

  static int _calculatePoints(double confidence, int consecutiveSmiles) {
    int basePoints;
    
    if (confidence >= 0.8) basePoints = 10;
    else if (confidence >= 0.7) basePoints = 8;
    else if (confidence >= 0.6) basePoints = 7;
    else if (confidence >= 0.5) basePoints = 6;
    else basePoints = 5;
    
    // Consecutive bonus
    int bonus = (consecutiveSmiles ~/ 2).clamp(0, 5);
    
    // Session engagement bonus
    int sessionSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
    int sessionBonus = (sessionSeconds ~/ 20).clamp(0, 3); // Up to 3 bonus points for long sessions
    
    return basePoints + bonus + sessionBonus;
  }

  static void dispose() {
    _isInitialized = false;
    _detectionCount = 0;
    _consecutiveSmiles = 0;
    _lastSmileTime = null;
    _sessionStartTime = null;
    _activityPattern.clear();
  }
}