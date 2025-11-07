import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/simple_smile_detection.dart';
import '../services/smile_rewards_service.dart';
import '../models/smile_models.dart';
import 'dart:async';

class SmileCameraScreen extends StatefulWidget {
  const SmileCameraScreen({super.key});

  @override
  State<SmileCameraScreen> createState() => _SmileCameraScreenState();
}

class _SmileCameraScreenState extends State<SmileCameraScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  Timer? _detectionTimer;
  
  // Animation controllers
  late AnimationController _smileAnimationController;
  late AnimationController _pointsAnimationController;
  late Animation<double> _smileScaleAnimation;
  late Animation<double> _pointsOpacityAnimation;

  // State variables
  SmileDetectionResult? _lastDetection;
  String _detectionStatus = 'Position your face in the camera';
  bool _showRewardAnimation = false;
  List<SmileReward> _recentRewards = [];
  int _sessionPoints = 0;
  int _sessionSmiles = 0;
  bool _isSessionActive = false;
  CameraDescription? _currentCamera;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
    SimpleSmileDetection.initialize();
  }

  void _initializeAnimations() {
    _smileAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pointsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _smileScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _smileAnimationController,
      curve: Curves.elasticOut,
    ));

    _pointsOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pointsAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _detectionStatus = 'Camera permission required';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _detectionStatus = 'No cameras available';
        });
        return;
      }

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _currentCamera = frontCamera; // Store the camera reference

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
        _detectionStatus = 'Tap "Start Session" to begin! New detection system active 🚀';
      });

    } catch (e) {
      setState(() {
        _detectionStatus = 'Camera initialization failed: $e';
      });
    }
  }

  void _startSmileSession() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isSessionActive = true;
      _sessionPoints = 0;
      _sessionSmiles = 0;
      _detectionStatus = 'Show your happiness! New smart detection system active 😊';
    });

    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async { // Faster detection
      if (!_isDetecting && mounted && _isSessionActive) {
        _isDetecting = true;
        
        try {
          // Ensure no stream is already running
          if (_cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
            await Future.delayed(const Duration(milliseconds: 100)); // Allow cleanup
          }
          
          _cameraController!.startImageStream((CameraImage image) async {
            if (!_isSessionActive || !mounted) {
              _isDetecting = false;
              try {
                await _cameraController?.stopImageStream();
              } catch (e) {
                // Stream already stopped
              }
              return;
            }

            final result = await SimpleSmileDetection.detectSmile(image, _currentCamera!);
            
            if (result != null && mounted) {
              setState(() {
                _lastDetection = result;
              });

              if (result.isSmiling) {
                await _onSmileDetected(result);
              } else {
                setState(() {
                  _detectionStatus = _getEncouragementMessage();
                });
              }
            }
            
            _isDetecting = false;
            // Stop stream immediately after processing
            try {
              await _cameraController?.stopImageStream();
            } catch (e) {
              // Stream already stopped
            }
          });
        } catch (e) {
          _isDetecting = false;
        }
      }
    });
  }

  void _stopSmileSession() {
    setState(() {
      _isSessionActive = false;
      _detectionStatus = 'Session ended! Well done! 🎉';
    });
    
    _detectionTimer?.cancel();
    _detectionTimer = null;
    
    // Ensure camera stream is properly stopped
    _stopCameraStreamSafely();

    // Show session summary
    _showSessionSummary();
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
                'Great job! Here\'s your session summary:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Smiles Detected', '$_sessionSmiles', '😊'),
              _buildSummaryRow('Points Earned', '$_sessionPoints', '🏆'),
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
      _recentRewards.clear();
      _lastDetection = null;
      _showRewardAnimation = false;
    });
    
    _startSmileSession();
  }

  Future<void> _onSmileDetected(SmileDetectionResult result) async {
    final rewards = await SmileRewardsService.processSmileDetection(result);
    
    setState(() {
      _sessionPoints += result.pointsEarned;
      _sessionSmiles += 1;
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

    setState(() {
      _detectionStatus = _getSmileMessage(result.smileConfidence);
    });
  }

  String _getSmileMessage(double confidence) {
    final messages = [
      'Amazing smile! Keep it up! 🌟',
      'Beautiful smile! You\'re glowing! ✨',
      'Perfect! That smile made my day! 😊',
      'Wonderful! Keep spreading joy! 🎉',
      'Fantastic smile! You\'re a natural! 💫',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  String _getEncouragementMessage() {
    final messages = [
      'Come on, let me see that smile! 😊',
      'Don\'t be shy, show me your best smile! 🌟',
      'I know you have a beautiful smile in there! ✨',
      'Smile! It\'s the best accessory you can wear! 💫',
      'Let that smile shine! I\'m waiting! 🎉',
    ];
    return messages[DateTime.now().millisecond % messages.length];
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
                    'Initializing camera...',
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

          // Top bar with session info
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('😊', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        '$_sessionSmiles',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Smiles',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        '$_sessionPoints',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Points',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // Debug info panel (top right)
          if (_isSessionActive && _lastDetection != null)
            Positioned(
              top: 120,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Raw: ${(_lastDetection!.smileConfidence * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                    Text(
                      'Detected: ${_lastDetection!.isSmiling ? "YES" : "NO"}',
                      style: TextStyle(
                        color: _lastDetection!.isSmiling ? Colors.green : Colors.red,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Points: ${_lastDetection!.pointsEarned}',
                      style: const TextStyle(color: Colors.yellow, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: AnimatedBuilder(
              animation: _smileScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _smileScaleAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _lastDetection?.isSmiling == true 
                            ? Colors.green 
                            : Colors.white.withOpacity(0.5),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _lastDetection?.isSmiling == true ? '😄' : '😐',
                            style: const TextStyle(fontSize: 60),
                          ),
                          if (_lastDetection != null)
                            Text(
                              '${(_lastDetection!.smileConfidence * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Smile naturally!\nAutomatic detection only',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Reward animation
          if (_showRewardAnimation)
            Center(
              child: AnimatedBuilder(
                animation: _pointsOpacityAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pointsOpacityAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _recentRewards.take(3).map((reward) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(reward.emoji, style: const TextStyle(fontSize: 30)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reward.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '+${reward.points} points',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
            ),

          // Bottom status and controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _detectionStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                if (!_isSessionActive)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isCameraInitialized ? _startSmileSession : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Start Smile Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _stopSmileSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'End Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Ensure session is stopped first
    _isSessionActive = false;
    
    // Cancel timer
    _detectionTimer?.cancel();
    _detectionTimer = null;
    
    // Stop camera stream before disposing controller
    _stopCameraStreamSafely().then((_) {
      // Dispose camera controller
      _cameraController?.dispose();
      _cameraController = null;
    });
    
    // Dispose animation controllers
    _smileAnimationController.dispose();
    _pointsAnimationController.dispose();
    
    // Cleanup smile detection
    SimpleSmileDetection.dispose();
    
    super.dispose();
  }
}