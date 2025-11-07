import 'package:flutter/material.dart';
import '../services/freesound_api_service.dart';
import '../services/premium_tts_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _testResults = 'Tap "Test APIs" to check your configuration...';
  bool _isLoading = false;

  Future<void> _runApiTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing APIs...\n';
    });

    try {
      // Test Freesound API
      String freesoundResult = await _testFreesoundApi();
      
      // Test Google TTS API  
      String ttsResult = await _testGoogleTtsApi();
      
      setState(() {
        _testResults = freesoundResult + '\n' + ttsResult;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _testResults = 'Error running tests: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _testFreesoundApi() async {
    String result = '🎵 FREESOUND API TEST:\n';
    
    try {
      // Test getting a sound URL
      String? rainUrl = await FreesoundApiService.getSoundDownloadUrl('2523');
      if (rainUrl != null) {
        result += '✅ API Connection: SUCCESS\n';
        result += '✅ Sound URL Retrieved: YES\n';
        result += '🔗 URL Sample: ${rainUrl.substring(0, 40)}...\n';
      } else {
        result += '❌ API Connection: FAILED\n';
        result += '⚠️ Check your API key\n';
      }
      
      // Test search
      List<Map<String, dynamic>> searchResults = await FreesoundApiService.searchSounds('ocean', count: 2);
      if (searchResults.isNotEmpty) {
        result += '✅ Search Function: SUCCESS\n';
        result += '📊 Found ${searchResults.length} sounds\n';
      } else {
        result += '❌ Search Function: FAILED\n';
      }
      
    } catch (e) {
      result += '❌ Error: $e\n';
    }
    
    return result;
  }

  Future<String> _testGoogleTtsApi() async {
    String result = '\n🗣️ GOOGLE TTS API TEST:\n';
    
    try {
      String? audioContent = await PremiumTTSService.generatePremiumAudio(
        'This is a test of premium voice generation.',
        'meditation_female_calm'
      );
      
      if (audioContent != null && audioContent.isNotEmpty) {
        result += '✅ API Connection: SUCCESS\n';
        result += '✅ Audio Generated: YES\n';
        result += '📦 Audio Size: ${audioContent.length} chars\n';
        result += '🎯 Voice Type: Meditation Female\n';
      } else {
        result += '❌ API Connection: FAILED\n';
        result += '⚠️ Check your API key and billing\n';
      }
      
    } catch (e) {
      result += '❌ Error: $e\n';
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Configuration Test'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Test Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.api,
                      size: 50,
                      color: Color(0xFF667eea),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'API Configuration Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Test your Freesound and Google TTS API keys',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _runApiTests,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Test APIs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Results Display
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResults,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}