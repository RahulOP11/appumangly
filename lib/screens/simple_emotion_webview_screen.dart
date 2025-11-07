import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleEmotionWebViewScreen extends StatefulWidget {
  final Uri url;
  const SimpleEmotionWebViewScreen({super.key, required this.url});

  @override
  State<SimpleEmotionWebViewScreen> createState() => _SimpleEmotionWebViewScreenState();
}

class _SimpleEmotionWebViewScreenState extends State<SimpleEmotionWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
            // Inject simple JavaScript with return button
            _controller.runJavaScript('''
              console.log('Page loaded, adding return button...');
              
              // Basic camera access setup
              if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
                console.log('getUserMedia API is available');
              }
              
              // Auto-click start button if it exists
              setTimeout(function() {
                var startBtn = document.querySelector('button');
                if (startBtn && (startBtn.textContent.includes('Start') || startBtn.textContent.includes('Restart'))) {
                  console.log('Auto-clicking Start/Restart button');
                  startBtn.click();
                }
              }, 2000);
              
              // Add return button after 8 seconds
              setTimeout(function() {
                console.log('Adding return to app button...');
                
                var returnButton = document.createElement('div');
                returnButton.id = 'umangly-return-btn';
                returnButton.innerHTML = \`
                  <div style="
                    position: fixed;
                    bottom: 20px;
                    right: 20px;
                    z-index: 9999;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 12px 20px;
                    border-radius: 25px;
                    font-family: Arial, sans-serif;
                    font-size: 14px;
                    font-weight: bold;
                    cursor: pointer;
                    box-shadow: 0 4px 15px rgba(0,0,0,0.3);
                    text-align: center;
                    animation: pulse 2s infinite;
                    user-select: none;
                  " onclick="returnToApp()">
                    🏠 Return to App
                  </div>
                  <style>
                    @keyframes pulse {
                      0% { transform: scale(1); opacity: 0.8; }
                      50% { transform: scale(1.05); opacity: 1; }
                      100% { transform: scale(1); opacity: 0.8; }
                    }
                  </style>
                \`;
                
                // Add to page
                document.body.appendChild(returnButton);
                
                // Define return function
                window.returnToApp = function() {
                  console.log('Return to app clicked');
                  window.flutter_inappwebview.postMessage('returnToApp');
                };
                
                console.log('Return button added successfully');
              }, 8000); // Show after 8 seconds
            ''');
          },
        ),
      )
      ..addJavaScriptChannel('flutter_inappwebview', onMessageReceived: (message) {
        print('Received message from WebView: ${message.message}');
        
        if (message.message == 'returnToApp') {
          print('User clicked return to app button');
          Navigator.of(context).pop({'emotion_smiles_completed': true, 'count': 3});
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
            Navigator.of(context).pop({'emotion_smiles_completed': false, 'count': 0});
          },
        ),
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
                    'A return button will appear after the page loads',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          // Instructions overlay
          if (!_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '😊 Smile at the camera 3 times, then use the return button to go back to the app!',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}