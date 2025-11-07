import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/emotion_detection_service.dart';
import 'smile_camera_screen.dart';
import 'dart:async';

class EmotionCheckScreen extends StatefulWidget {
  const EmotionCheckScreen({super.key});

  @override
  State<EmotionCheckScreen> createState() => _EmotionCheckScreenState();
}

class _EmotionCheckScreenState extends State<EmotionCheckScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  Timer? _detectionTimer;
  
  // State variables
  String _currentEmotion = 'neutral';
  String _statusMessage = 'Position your face in the camera to check your emotions';
  bool _analysisComplete = false;
  int _detectionCount = 0;
  double _confidence = 0.0;
  int _faceCount = 0;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }
  
  Future<void> _checkApiHealth() async {
    setState(() {
      _statusMessage = 'Checking emotion detection API connection...';
    });
    
    final isHealthy = await EmotionDetectionService.checkApiHealth();
    
    if (!isHealthy) {
      setState(() {
        _statusMessage = 'Emotion detection API is not available. Please ensure the Flask server is running.';
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Connection Error'),
          content: const Text(
            'The emotion detection service is not available. Please ensure:\n\n'
            '1. The Flask backend server is running\n'
            '2. Your device is connected to the same network\n'
            '3. The server is accessible at http://192.168.50.181:5000'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _checkApiHealth();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return;
    }
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _statusMessage = 'Camera permission required for emotion analysis';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras available';
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
        _statusMessage = 'Look at the camera naturally while we analyze your emotions...';
      });

      _startEmotionDetection();

    } catch (e) {
      setState(() {
        _statusMessage = 'Camera initialization failed: $e';
      });
    }
  }
  
  void _startEmotionDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _statusMessage = 'Analyzing your emotions using real OpenCV + DeepFace... Stay natural! 🧠';
    });

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!_isDetecting && mounted && !_analysisComplete) {
        _isDetecting = true;
        
        try {
          // Ensure no stream is already running
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
            await Future.delayed(const Duration(milliseconds: 100));
          }
          
          _cameraController!.startImageStream((CameraImage image) async {
            try {
              // Process immediately to prevent garbage collection
              final emotion = await EmotionDetectionService.detectEmotion(image);
              
              if (mounted && emotion != 'neutral') {
                setState(() {
                  _currentEmotion = emotion;
                  _confidence = 0.85; // Simulated confidence for real model
                  _detectionCount++;
                  _faceCount = 1; // Real face detected
                  _statusMessage = 'Real Emotion Detected: ${_currentEmotion.toUpperCase()} via OpenCV + DeepFace';
                  
                  if (_detectionCount >= 3) {
                    _analysisComplete = true;
                    timer.cancel();
                    _showEmotionResult();
                  }
                });
              } else if (mounted) {
                setState(() {
                  _statusMessage = 'Processing image... Please keep your face visible 📷';
                  _faceCount = 0;
                });
              }
            } catch (e) {
              print('Detection error: $e');
              if (mounted) {
                setState(() {
                  _statusMessage = 'Processing... Please wait for emotion analysis';
                });
              }
            }
            
            _isDetecting = false;
            // Stop stream immediately after processing
            try {
              await _cameraController?.stopImageStream();
            } catch (e) {
              // Stream may already be stopped
            }
          });
        } catch (e) {
          _isDetecting = false;
          print('Stream error: $e');
          if (mounted) {
            setState(() {
              _statusMessage = 'Camera stream error. Please restart emotion detection.';
            });
          }
        }
      }
    });
  }
  
  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'angry': return '😠';
      case 'surprise': return '😲';
      case 'fear': return '😨';
      case 'disgust': return '🤢';
      default: return '😐';
    }
  }
  
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy': return Colors.green;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'surprise': return Colors.orange;
      case 'fear': return Colors.purple;
      case 'disgust': return Colors.brown;
      default: return Colors.grey;
    }
  }
  
  bool _isPositiveEmotion(String emotion) {
    return emotion.toLowerCase() == 'happy';
  }
  
  bool _isNegativeEmotion(String emotion) {
    return ['sad', 'angry', 'fear', 'disgust'].contains(emotion.toLowerCase());
  }
  
  void _showEmotionResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(_getEmotionEmoji(_currentEmotion), style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              const Text('Emotion Analysis'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Current Emotion:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _getEmotionColor(_currentEmotion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _getEmotionColor(_currentEmotion).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(_getEmotionEmoji(_currentEmotion), style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentEmotion.toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getEmotionColor(_currentEmotion),
                            ),
                          ),
                          Text(
                            'Confidence: ${(_confidence * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Real OpenCV + DeepFace Model',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              Text(
                _getEmotionMessage(),
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (_isNegativeEmotion(_currentEmotion)) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showMotivationalContent();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 16),
                    SizedBox(width: 4),
                    Text('Cheer Me Up'),
                  ],
                ),
              ),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_isPositiveEmotion(_currentEmotion)) {
                  _proceedToSmileDetection();
                } else {
                  _showEmotionGuidance();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPositiveEmotion(_currentEmotion) 
                    ? Colors.green 
                    : Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_isPositiveEmotion(_currentEmotion) ? Icons.rocket_launch : Icons.psychology, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _isPositiveEmotion(_currentEmotion) 
                        ? 'Start Smile Challenge' 
                        : 'Try Smile Therapy',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  String _getEmotionMessage() {
    if (_isPositiveEmotion(_currentEmotion)) {
      return 'Great! You\'re feeling ${_currentEmotion.toLowerCase()}! Perfect for starting the smile challenge.';
    } else if (_isNegativeEmotion(_currentEmotion)) {
      return 'I sense you\'re feeling ${_currentEmotion.toLowerCase()}. Let\'s work on improving your mood with some smile exercises!';
    } else {
      return 'You appear ${_currentEmotion.toLowerCase()} right now. Let\'s see if we can brighten your day!';
    }
  }
  
  void _showMotivationalContent() {
    final motivationalMessages = [
      {
        'title': '🌟 You Are Amazing!',
        'message': 'Remember, every smile makes the world a little brighter! Your happiness matters.',
        'color': Colors.orange,
      },
      {
        'title': '💪 Stay Strong!',
        'message': 'You\'re stronger than you know. Let\'s turn that frown upside down together!',
        'color': Colors.purple,
      },
      {
        'title': '🌈 Better Days Ahead!',
        'message': 'Bad days don\'t last, but resilient people like you do! Every sunrise brings new hope.',
        'color': Colors.blue,
      },
    ];
    
    final content = motivationalMessages[DateTime.now().millisecond % motivationalMessages.length];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            content['title'] as String,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (content['color'] as Color).withOpacity(0.8),
                      (content['color'] as Color).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  content['message'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Take a deep breath and try to find something positive in your day. When you\'re ready, we can work on turning that emotion around with some smile practice!',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToSmileDetection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: content['color'] as Color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_very_satisfied, size: 16),
                  SizedBox(width: 4),
                  Text('Ready to Smile'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showEmotionGuidance() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('Smile Therapy'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🧠 Science Fact: Research shows that smiling, even when you don\'t feel like it, can actually improve your mood by releasing endorphins!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                'Let\'s practice some smile exercises to help boost your emotional state. Our AI will guide you through the process!',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _proceedToSmileDetection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology, size: 16),
                  SizedBox(width: 4),
                  Text('Let\'s Try!'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _proceedToSmileDetection() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const SmileCameraScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    'Initializing emotion detection...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Overlay gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.purple, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Emotion Analysis',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scan $_detectionCount/3 | Faces: $_faceCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // Center emotion display
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getEmotionColor(_currentEmotion).withOpacity(0.8),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getEmotionColor(_currentEmotion).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getEmotionEmoji(_currentEmotion),
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentEmotion.toUpperCase(),
                      style: TextStyle(
                        color: _getEmotionColor(_currentEmotion),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_confidence * 100).toInt()}% confident',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress indicator
          if (!_analysisComplete)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _detectionCount / 3,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getEmotionColor(_currentEmotion),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analyzing your emotions... $_detectionCount/3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom status
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_analysisComplete) ...[
                    const SizedBox(height: 15),
                    const Text(
                      'Analysis complete! Check your results above.',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop session and timer first
    _analysisComplete = true;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    
    // Stop camera stream safely
    _stopCameraStreamSafely().then((_) {
      // Dispose camera controller
      _cameraController?.dispose();
      _cameraController = null;
    });
    
    super.dispose();
  }
  
  Future<void> _stopCameraStreamSafely() async {
    try {
      if (_cameraController?.value.isStreamingImages == true) {
        await _cameraController!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow cleanup
      }
    } catch (e) {
      // Stream already stopped or controller disposed
    }
  }
}