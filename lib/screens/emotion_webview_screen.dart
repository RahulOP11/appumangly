import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class EmotionWebViewScreen extends StatefulWidget {
  final Uri url;
  const EmotionWebViewScreen({
    super.key, 
    required this.url,
  });

  @override
  State<EmotionWebViewScreen> createState() => _EmotionWebViewScreenState();
}

class _EmotionWebViewScreenState extends State<EmotionWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _dailySmiles = 0;
  static const String _kSmileKey = 'daily_smiles_count';
  static const String _kSmileDateKey = 'daily_smiles_date';
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _requestCameraPermission();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..enableZoom(false)
      ..setBackgroundColor(Colors.white)
      ..clearCache()
      ..clearLocalStorage()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            // Inject JavaScript for camera access and return button
            _controller.runJavaScript('''
              console.log('Page loaded, setting up camera access and return button...');
              
              // Basic camera access setup
              if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                console.log('getUserMedia API is available');
                
                // Override getUserMedia for better permission handling
                const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
                navigator.mediaDevices.getUserMedia = function(constraints) {
                  console.log('Camera access requested with constraints:', constraints);
                  return originalGetUserMedia(constraints)
                    .then(stream => {
                      console.log('Camera access granted successfully');
                      return stream;
                    })
                    .catch(error => {
                      console.error('Camera access error:', error);
                      // Try fallback with different constraints
                      return originalGetUserMedia({
                        video: { facingMode: 'user' },
                        audio: false
                      });
                    });
                };
              } else {
                console.error('getUserMedia API not available');
              }
              
              // Auto-click start button if it exists
              setTimeout(function() {
                var startBtn = document.querySelector('button');
                if (startBtn && startBtn.textContent.includes('Start')) {
                  console.log('Auto-clicking Start button');
                  startBtn.click();
                }
              }, 2000);
              
              // Monitor smile counts and show return button with enhanced debugging
              var returnButtonAdded = false;
              var checkCount = 0;
              var smileCheckInterval = setInterval(function() {
                try {
                  checkCount++;
                  var totalSmiles = 0;
                  
                  console.log('=== Smile Check #' + checkCount + ' ===');
                  
                  // Look for smile counter elements with multiple detection methods
                  var h5Elements = document.querySelectorAll('h5');
                  console.log('Found', h5Elements.length, 'h5 elements');
                  
                  h5Elements.forEach(function(h5, index) {
                    var text = h5.textContent || h5.innerText || '';
                    console.log('H5[' + index + ']:', text);
                    
                    // Method 1: "Person X Smiles: Y" pattern
                    if (text.includes('Person') && text.includes('Smiles:')) {
                      var match = text.match(/Smiles:\\s*(\\d+)/);
                      if (match) {
                        var count = parseInt(match[1]);
                        if (!isNaN(count) && count >= 0) {
                          totalSmiles += count;
                          console.log('✅ Found smile count:', count, 'from:', text);
                        }
                      }
                    }
                  });
                  
                  // Method 2: Fallback - look for any element with "Smiles:" pattern
                  if (totalSmiles === 0) {
                    console.log('No smiles found in h5, trying fallback method...');
                    var allElements = document.querySelectorAll('*');
                    var checkedElements = 0;
                    allElements.forEach(function(el) {
                      var text = el.textContent || el.innerText || '';
                      if (text.includes('Smiles:') && text.length < 100) {
                        checkedElements++;
                        var match = text.match(/Smiles:\\s*(\\d+)/);
                        if (match) {
                          var count = parseInt(match[1]);
                          if (!isNaN(count) && count >= 0 && count <= 20) {
                            totalSmiles += count;
                            console.log('✅ Fallback found:', count, 'from:', text.substring(0, 50));
                          }
                        }
                      }
                    });
                    console.log('Checked', checkedElements, 'elements in fallback');
                  }
                  
                  console.log('📊 Total smiles detected:', totalSmiles);
                  
                  // Show return button when 3+ smiles detected
                  if (totalSmiles >= 3 && !returnButtonAdded) {
                    console.log('3+ smiles detected! Adding return to app button...');
                    returnButtonAdded = true;
                    
                    // Create return button
                    var returnButton = document.createElement('div');
                    returnButton.id = 'umangly-return-btn';
                    returnButton.innerHTML = \`
                      <div style="
                        position: fixed;
                        top: 20px;
                        left: 50%;
                        transform: translateX(-50%);
                        z-index: 9999;
                        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                        color: white;
                        padding: 15px 25px;
                        border-radius: 25px;
                        font-family: Arial, sans-serif;
                        font-size: 16px;
                        font-weight: bold;
                        cursor: pointer;
                        box-shadow: 0 4px 15px rgba(0,0,0,0.3);
                        text-align: center;
                        animation: bounce 2s infinite;
                      ">
                        🎉 Great job! \${totalSmiles} smiles completed!<br>
                        <span style="font-size: 14px;">Tap here to return to Umangly app</span>
                      </div>
                      <style>
                        @keyframes bounce {
                          0%, 20%, 50%, 80%, 100% { transform: translateX(-50%) translateY(0); }
                          40% { transform: translateX(-50%) translateY(-10px); }
                          60% { transform: translateX(-50%) translateY(-5px); }
                        }
                      </style>
                    \`;
                    
                    // Add click handler
                    returnButton.onclick = function() {
                      window.flutter_inappwebview.postMessage(JSON.stringify({
                        type: 'returnToApp',
                        smileCount: totalSmiles,
                        completed: true
                      }));
                    };
                    
                    document.body.appendChild(returnButton);
                    
                    // Also notify Flutter immediately
                    window.flutter_inappwebview.postMessage(JSON.stringify({
                      type: 'smilesCompleted',
                      count: totalSmiles
                    }));
                  }
                  
                } catch (error) {
                  console.error('Error in smile monitoring:', error);
                }
              }, 2000); // Check every 2 seconds
            ''');
          },
          onNavigationRequest: (request) {
            // Listen for a deep link-like redirect: umangly://emotion-complete?smiles=3
            final uri = Uri.parse(request.url);
            if (uri.scheme == 'umangly' && uri.host == 'emotion-complete') {
              final smiles = int.tryParse(uri.queryParameters['smiles'] ?? '0') ?? 0;
              _handleSmilesFromWeb(smiles);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel('flutter_inappwebview', onMessageReceived: (message) {
        // Handle messages from WebView
        print('Received message from WebView: ${message.message}');
        
        try {
          if (message.message.contains('returnToApp')) {
            // User clicked the return button after completing smiles
            final regex = RegExp(r'"smileCount":(\d+)');
            final match = regex.firstMatch(message.message);
            final count = match != null ? int.parse(match.group(1)!) : 3;
            
            print('User requested return to app with $count smiles');
            _handleSmilesFromWeb(count);
          } else if (message.message.contains('smilesCompleted')) {
            // Update smile count in real-time when 3+ smiles detected
            final regex = RegExp(r'"count":(\d+)');
            final match = regex.firstMatch(message.message);
            if (match != null) {
              final count = int.parse(match.group(1)!);
              setState(() {
                _dailySmiles = count;
              });
              print('Smiles completed: $count - Return button should be visible');
            }
          }
        } catch (e) {
          print('Error parsing WebView message: $e');
        }
      })
      ..addJavaScriptChannel('Umangly', onMessageReceived: (message) {
        // Expect messages like: {"type":"smile","count":1}
        try {
          final text = message.message;
          // Simple parsing for the common format: smile:1 or completed:3
          if (text.startsWith('smile:')) {
            final val = int.tryParse(text.split(':')[1]) ?? 0;
            _incrementSmiles(val);
          } else if (text.startsWith('completed:')) {
            final val = int.tryParse(text.split(':')[1]) ?? 0;
            if (val >= 3) _completeAndReturn();
          }
        } catch (e) {
          // ignore parse errors
        }
      })
      ..loadRequest(widget.url);
  }

  Future<void> _requestCameraPermission() async {
    final permission = await Permission.camera.status;
    if (!permission.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _resetIfNewDay();
    setState(() {
      _dailySmiles = _prefs.getInt(_kSmileKey) ?? 0;
    });
  }

  void _resetIfNewDay() {
    final lastDate = _prefs.getString(_kSmileDateKey);
    final today = DateTime.now().toIso8601String().split('T').first;
    if (lastDate != today) {
      _prefs.setInt(_kSmileKey, 0);
      _prefs.setString(_kSmileDateKey, today);
    }
  }

  Future<void> _incrementSmiles(int count) async {
    _dailySmiles += count;
    await _prefs.setInt(_kSmileKey, _dailySmiles);

    if (_dailySmiles >= 3) {
      await Future.delayed(const Duration(milliseconds: 400));
      _completeAndReturn();
    } else {
      setState(() {});
    }
  }

  Future<void> _handleSmilesFromWeb(int smiles) async {
    if (smiles <= 0) return;
    await _incrementSmiles(smiles);
  }

  void _completeAndReturn() {
    // Return with completion result
    Navigator.of(context).pop({'emotion_smiles_completed': true, 'count': _dailySmiles});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Emotion Detection',
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop({'emotion_smiles_completed': false, 'count': _dailySmiles});
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Smiles: $_dailySmiles/3',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading emotion detection...',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please allow camera access when prompted',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
