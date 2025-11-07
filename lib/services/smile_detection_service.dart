import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import '../models/smile_models.dart';
import 'offline_emotion_detection_service.dart';

class SmileDetectionService {
  static bool _isInitialized = false;
  static int _consecutiveSmiles = 0;
  static DateTime? _lastSmileTime;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the offline emotion detection service
      await OfflineEmotionDetectionService.initialize();
      _isInitialized = true;
      print('✅ Smile Detection Service initialized with offline emotion detection');
    } catch (e) {
      print('❌ Error initializing Smile Detection Service: $e');
    }
  }

  static Future<SmileDetectionResult?> detectSmile(CameraImage cameraImage, [CameraDescription? camera]) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Use the offline emotion detection service to detect emotions
      final emotionResult = await OfflineEmotionDetectionService.detectEmotion(cameraImage);
      
      if (emotionResult == null) {
        return null;
      }

      // Convert emotion result to smile detection result
      final isSmiling = emotionResult.isSmiling;
      final confidence = emotionResult.smileConfidence;

      if (isSmiling) {
        _consecutiveSmiles++;
        _lastSmileTime = DateTime.now();
      } else {
        _consecutiveSmiles = 0;
      }

      // Calculate enhanced confidence based on consecutive detections
      final enhancedConfidence = _calculateEnhancedConfidence(confidence, _consecutiveSmiles);
      
      // Calculate points based on smile quality and consistency
      final points = _calculatePoints(enhancedConfidence, _consecutiveSmiles);

      print('😊 Smile Detection: ${(enhancedConfidence * 100).toStringAsFixed(1)}% | Points: $points | Consecutive: $_consecutiveSmiles');

      return SmileDetectionResult(
        isSmiling: isSmiling,
        smileConfidence: enhancedConfidence,
        timestamp: DateTime.now(),
        pointsEarned: points,
      );

    } catch (e) {
      print('❌ Error in smile detection: $e');
      return null;
    }
  }

  static double _calculateEnhancedConfidence(double baseConfidence, int consecutiveCount) {
    // Boost confidence based on consistency
    double enhancement = math.min(consecutiveCount * 0.1, 0.3);
    return math.min(baseConfidence + enhancement, 1.0);
  }

  static int _calculatePoints(double confidence, int consecutiveCount) {
    int basePoints = 0;
    
    // Base points from confidence
    if (confidence >= 0.9) basePoints = 10;
    else if (confidence >= 0.8) basePoints = 8;
    else if (confidence >= 0.7) basePoints = 6;
    else if (confidence >= 0.6) basePoints = 4;
    else if (confidence >= 0.5) basePoints = 2;
    else basePoints = 1;

    // Bonus points for consistency
    int consistencyBonus = math.min(consecutiveCount ~/ 3, 5);
    
    return basePoints + consistencyBonus;
  }

  static Future<List<Rect>?> detectFaces(CameraImage cameraImage) async {
    // Use the offline emotion detection service for face detection
    return await OfflineEmotionDetectionService.detectFaces(cameraImage);
  }

  static void dispose() {
    _consecutiveSmiles = 0;
    _lastSmileTime = null;
    _isInitialized = false;
    OfflineEmotionDetectionService.dispose();
    print('🧹 Smile Detection Service disposed');
  }

  // Utility methods for backward compatibility
  static bool isLikelySmiling(double smileProbability) {
    return smileProbability > 0.6;
  }

  static String getSmileQuality(double confidence) {
    if (confidence >= 0.9) return "Excellent";
    if (confidence >= 0.8) return "Great";
    if (confidence >= 0.7) return "Good";
    if (confidence >= 0.6) return "Fair";
    return "Weak";
  }

  static Color getSmileColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF4CAF50); // Green
    if (confidence >= 0.6) return const Color(0xFF2196F3); // Blue
    if (confidence >= 0.4) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  // Statistics
  static int get consecutiveSmiles => _consecutiveSmiles;
  static DateTime? get lastSmileTime => _lastSmileTime;
  static bool get isInitialized => _isInitialized;
}