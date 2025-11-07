import '../models/smile_models.dart';
import 'dart:math';

class FallbackSmileDetection {
  static int _tapCount = 0;
  static DateTime? _lastTap;
  static double _randomSmileConfidence = 0.5;

  /// Simple tap-to-smile fallback when ML Kit fails
  static SmileDetectionResult simulateSmileDetection() {
    final now = DateTime.now();
    
    // Simulate varying smile confidence
    _randomSmileConfidence = 0.3 + (Random().nextDouble() * 0.7); // 0.3 to 1.0
    
    // Consider it a smile if recent tap or random chance
    bool isSmiling = _isRecentTap(now) || _randomSmileConfidence > 0.8;
    
    int points = isSmiling ? _calculateSimplePoints(_randomSmileConfidence) : 0;
    
    print('🤖 Fallback detection - Smiling: $isSmiling, Confidence: ${_randomSmileConfidence.toStringAsFixed(2)}, Points: $points');
    
    return SmileDetectionResult(
      isSmiling: isSmiling,
      smileConfidence: _randomSmileConfidence,
      timestamp: now,
      pointsEarned: points,
    );
  }

  static void registerTap() {
    _tapCount++;
    _lastTap = DateTime.now();
    print('👆 Tap registered! Count: $_tapCount');
  }

  static bool _isRecentTap(DateTime now) {
    return _lastTap != null && now.difference(_lastTap!).inSeconds < 2;
  }

  static int _calculateSimplePoints(double confidence) {
    if (confidence >= 0.9) return 10;
    if (confidence >= 0.7) return 8;
    if (confidence >= 0.5) return 6;
    if (confidence >= 0.3) return 4;
    return 3;
  }

  static void reset() {
    _tapCount = 0;
    _lastTap = null;
    _randomSmileConfidence = 0.5;
  }
}