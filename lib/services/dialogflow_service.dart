import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/virtual_friend_models.dart';

class DialogflowService {
  // Your Dialogflow project configuration
  static const String _projectId = 'umangly-app';
  static const String _agentId = '63a27262-c7a4-4ff7-9cba-170ec03cc212';
  static const String _location = 'global';
  
  // Cache for access token
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  Future<String> detectIntent({
    required String sessionId,
    required String text,
    String? languageCode = 'en',
    VirtualFriend? friend,
  }) async {
    print('DialogflowService: Processing message for Arav - "$text"');
    
    try {
      // Try to make a real Dialogflow API call
      final response = await _makeDialogflowRequest(sessionId, text, languageCode);
      print('DialogflowService: Successfully got response from Dialogflow API');
      return response;
    } catch (e) {
      print('DialogflowService: API call failed, using fallback response: $e');
      // Fallback to Arav-style responses
      return await _generateAravStyleResponse(text, friend, sessionId);
    }
  }

  Future<String> _makeDialogflowRequest(String sessionId, String text, String? languageCode) async {
    try {
      // Load service account credentials from assets
      final configString = await rootBundle.loadString('assets/dialogflow_config.json');
      final serviceAccount = json.decode(configString);
      
      // Validate that we have real credentials
      if (!serviceAccount.containsKey('private_key') || 
          serviceAccount['private_key'].toString().contains('YOUR_PRIVATE_KEY')) {
        throw Exception('Service account credentials not configured properly');
      }
      
      print('DialogflowService: Attempting to authenticate with service account...');
      
      // Get access token
      final accessToken = await _getAccessToken(serviceAccount);
      
      print('DialogflowService: Successfully authenticated, making API request...');
      
      // Make the Dialogflow CX API request (not ES)
      final url = 'https://dialogflow.googleapis.com/v3/projects/$_projectId/locations/$_location/agents/$_agentId/sessions/$sessionId:detectIntent';
      
      final requestBody = {
        'queryInput': {
          'text': {
            'text': text,
          },
          'languageCode': languageCode ?? 'en',
        }
      };
      
      print('DialogflowService: Sending request to: $url');
      print('DialogflowService: Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(requestBody),
      );
      
      print('DialogflowService: Response status: ${response.statusCode}');
      print('DialogflowService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // For Dialogflow CX, the response structure is different
        final fulfillmentText = responseData['queryResult']['responseMessages']?[0]?['text']?['text']?[0] ??
                               responseData['queryResult']['fulfillmentText'];
        final detectedIntent = responseData['queryResult']['intent']?['displayName'] ?? 'Unknown';
        
        print('DialogflowService: Detected intent: $detectedIntent');
        print('DialogflowService: Fulfillment text: $fulfillmentText');
        
        return fulfillmentText ?? 'I didn\'t understand that, but I\'m here to help you stay motivated! 💪';
      } else {
        print('DialogflowService: API error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Dialogflow API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DialogflowService: Failed to call Dialogflow API: $e');
      // Re-throw to trigger fallback
      throw Exception('Failed to call Dialogflow: $e');
    }
  }

  Future<String> _getAccessToken(Map<String, dynamic> serviceAccount) async {
    // Check if we have a valid cached token
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      print('DialogflowService: Using cached access token');
      return _accessToken!;
    }

    try {
      print('DialogflowService: Getting new access token...');
      
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      
      print('DialogflowService: Created credentials for: ${credentials.email}');
      
      final client = await clientViaServiceAccount(
        credentials, 
        ['https://www.googleapis.com/auth/cloud-platform']
      );
      
      final accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        client,
      );
      
      _accessToken = accessCredentials.accessToken.data;
      _tokenExpiry = accessCredentials.accessToken.expiry;
      
      print('DialogflowService: Successfully obtained access token, expires at: $_tokenExpiry');
      
      client.close();
      return _accessToken!;
    } catch (e) {
      print('DialogflowService: Failed to get access token: $e');
      throw Exception('Failed to get access token: $e');
    }
  }  // This is a temporary implementation that mimics Dialogflow responses for Arav
  Future<String> _generateAravStyleResponse(String userMessage, VirtualFriend? friend, String sessionId) async {
    final message = userMessage.toLowerCase();
    
    // Arav's motivational and energetic responses based on common patterns
    if (message.contains('help') || message.contains('support')) {
      return "I'm absolutely here to help you! You know what? You've already taken the first step by reaching out. That shows real courage! What specifically would you like to tackle together? 💪";
    }
    
    if (message.contains('sad') || message.contains('down') || message.contains('depressed')) {
      return "Hey, I hear you, and it's totally okay to feel down sometimes. But you know what I see in you? Strength! Even when you're feeling low, you're still here, still fighting. That's the spirit of a champion! Let's find something small we can do right now to boost your energy. How about we start with taking three deep breaths together? 🌟";
    }
    
    if (message.contains('motivated') || message.contains('inspire') || message.contains('energy')) {
      return "YES! Now that's the energy I love to hear! You're like a spark that's ready to become a fire! 🔥 Here's what I want you to remember: every great journey starts with a single step, and you're already moving forward. What's one goal you've been thinking about? Let's turn that dream into an action plan!";
    }
    
    if (message.contains('tired') || message.contains('exhausted') || message.contains('rest')) {
      return "I totally get that! Even the strongest athletes need rest and recovery. You know what's awesome? Recognizing when you need to recharge. That's wisdom! Take the rest you need, but remember - tomorrow is a fresh start full of possibilities. When you're ready, I'll be here to cheer you on! 🌅";
    }
    
    if (message.contains('workout') || message.contains('exercise') || message.contains('fitness')) {
      return "Now we're talking! Fitness is one of my favorite topics! 💪 Movement is medicine for both body and mind. Whether it's a full workout or just a 10-minute walk, every bit counts. What kind of movement sounds good to you today? Let's find something that gets your blood pumping and your spirits high!";
    }
    
    if (message.contains('goal') || message.contains('dream') || message.contains('achieve')) {
      return "Goals and dreams - that's where the magic happens! 🎯 You know what separates dreamers from achievers? Action! And guess what? You're already taking action by talking about it. Tell me about this goal of yours. Let's break it down into small, achievable steps. Remember: every expert was once a beginner!";
    }
    
    if (message.contains('afraid') || message.contains('scared') || message.contains('fear')) {
      return "Fear? That's just excitement without the breath! 😤 Everyone feels fear - even the most successful people. But here's the secret: courage isn't the absence of fear, it's feeling fear and moving forward anyway. You're braver than you believe and stronger than you know. What's one tiny step you could take toward what scares you?";
    }
    
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return "Hey there, champion! 🌟 Great to see you! I'm feeling super energetic today and ready to help you tackle anything. Whether you want motivation, need to talk through something, or just want to share what's awesome in your life - I'm all ears! What's bringing you here today?";
    }
    
    if (message.contains('thank')) {
      return "Aw, you're so welcome! But here's the thing - YOU did the hard work! I'm just here cheering from the sidelines. You've got this incredible strength inside you, and I'm honored to be part of your journey. Keep being amazing! 🙌";
    }
    
    // Default Arav response
    return "You know what I love about talking with you? Your energy! Whatever's on your mind, I'm here for it. I believe in the power of positive thinking and taking action. So tell me - what's one thing that's exciting you right now, or what's something you'd like to work on together? Let's turn today into something amazing! 🚀";
  }
}

// Instructions for setting up proper Dialogflow integration:
/*
TO SET UP PROPER DIALOGFLOW INTEGRATION:

1. Enable the Dialogflow API in your Google Cloud Console
2. Create a service account and download the JSON key file
3. Add the googleapis package to pubspec.yaml:
   dependencies:
     googleapis: ^11.4.0
     googleapis_auth: ^1.4.1

4. Replace the mock implementation above with proper API calls:

class DialogflowService {
  static const String _credentialsPath = 'path/to/your/service-account.json';
  
  Future<String> detectIntent({
    required String sessionId,
    required String text,
    String? languageCode = 'en',
  }) async {
    // Load service account credentials
    final credentials = ServiceAccountCredentials.fromJson(
      await File(_credentialsPath).readAsString()
    );
    
    // Create authenticated client
    final client = await clientViaServiceAccount(
      credentials, 
      ['https://www.googleapis.com/auth/cloud-platform']
    );
    
    // Create Dialogflow client
    final dialogflow = DialogflowApi(client);
    
    // Make the detect intent request
    final request = GoogleCloudDialogflowV2DetectIntentRequest(
      queryInput: GoogleCloudDialogflowV2QueryInput(
        text: GoogleCloudDialogflowV2TextInput(
          text: text,
          languageCode: languageCode,
        ),
      ),
    );
    
    final response = await dialogflow.projects.agent.sessions.detectIntent(
      request,
      'projects/$_projectId/agent/sessions/$sessionId',
    );
    
    return response.queryResult?.fulfillmentText ?? 'I didn\'t understand that.';
  }
}

5. Update your Dialogflow agent to have intents that match Arav's personality
6. Train your agent with sample phrases and responses
7. Test the integration

For now, the mock implementation above provides Arav-style responses without requiring
the full Dialogflow setup, so you can test the integration flow.
*/