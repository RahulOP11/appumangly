import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/virtual_friend_models.dart';

class GeminiAIService {
  static const String _apiKey = 'AIzaSyCwIu9wwwo0Cn2M9iEqBMyhdu5DgZ_Fyy0';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> generateFriendResponse({
    required VirtualFriend friend,
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    String? userMood,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Build conversation context
      final conversationContext = _buildConversationContext(
        friend: friend,
        userMessage: userMessage,
        history: conversationHistory,
        userMood: userMood,
        context: context,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': conversationContext}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.9,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 400,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? _getFallbackResponse(friend);
          }
        }
      }

      return _getFallbackResponse(friend);
    } catch (e) {
      print('Error generating AI response: $e');
      return _getFallbackResponse(friend);
    }
  }

  String _buildConversationContext({
    required VirtualFriend friend,
    required String userMessage,
    required List<ChatMessage> history,
    String? userMood,
    Map<String, dynamic>? context,
  }) {
    final buffer = StringBuffer();

    // Friend personality and role
    buffer.writeln('You are ${friend.name}, a virtual friend with the following characteristics:');
    buffer.writeln('- Gender: ${friend.gender}');
    buffer.writeln('- Personality: ${friend.personality}');
    buffer.writeln('- Backstory: ${friend.backstory}');
    buffer.writeln('- Interests: ${friend.interests.join(", ")}');
    buffer.writeln('- Voice Type: ${friend.voiceType}');
    buffer.writeln();

    // Behavioral guidelines
    buffer.writeln('Guidelines for your responses:');
    buffer.writeln('- Be supportive, friendly, and engaging');
    buffer.writeln('- Keep responses conversational and natural');
    buffer.writeln('- Show genuine interest in the user\'s wellbeing');
    buffer.writeln('- Use emojis occasionally but not excessively');
    buffer.writeln('- Respond with 1-3 sentences unless a longer response is needed');
    buffer.writeln('- Be empathetic and understanding');
    buffer.writeln('- Stay in character based on your personality');
    buffer.writeln('- Focus on mental wellness and positive interactions');
    buffer.writeln();

    // User context
    if (userMood != null) {
      buffer.writeln('The user\'s current mood is: $userMood');
    }

    if (context != null && context.isNotEmpty) {
      buffer.writeln('Additional context: ${context.toString()}');
    }
    buffer.writeln();

    // Conversation history (last 10 messages for context)
    if (history.isNotEmpty) {
      buffer.writeln('Recent conversation history:');
      final recentHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
      
      for (final message in recentHistory) {
        final sender = message.isFromUser ? 'User' : friend.name;
        buffer.writeln('$sender: ${message.message}');
      }
      buffer.writeln();
    }

    // Current user message
    buffer.writeln('User just said: "$userMessage"');
    buffer.writeln();
    buffer.writeln('Respond as ${friend.name} in a helpful, friendly, and engaging way:');

    return buffer.toString();
  }

  String _getFallbackResponse(VirtualFriend friend) {
    final fallbacks = [
      "I'm here for you! How are you feeling today? 😊",
      "That's interesting! Tell me more about what's on your mind.",
      "I appreciate you sharing that with me. What would you like to talk about?",
      "I'm always here to listen and chat with you! 💙",
      "Let's talk about something that makes you happy! What brings you joy?",
    ];

    if (friend.gender.toLowerCase() == 'female') {
      fallbacks.addAll([
        "I love our conversations! What's been the highlight of your day? ✨",
        "You know I'm always here for you, right? 💕",
        "I'm curious about your thoughts! Share anything that's on your mind.",
      ]);
    } else {
      fallbacks.addAll([
        "Hey there! What's going on in your world today?",
        "I'm here to chat whenever you need a friend! 👍",
        "What's been keeping you busy lately?",
      ]);
    }

    fallbacks.shuffle();
    return fallbacks.first;
  }

  Future<List<String>> generateActivitySuggestions({
    required VirtualFriend friend,
    required String userMood,
    List<String>? userInterests,
  }) async {
    try {
      final prompt = '''
As ${friend.name}, suggest 3-5 fun activities or conversation topics for someone who is feeling $userMood.
Consider these interests: ${userInterests?.join(", ") ?? "general wellness, mindfulness, creativity"}
Keep suggestions positive, engaging, and suitable for a virtual friend chat.
Format as a simple list, one activity per line.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] ?? '';
            return text.split('\n')
                .where((line) => line.trim().isNotEmpty)
                .map((line) => line.trim())
                .toList();
          }
        }
      }

      return _getDefaultActivitySuggestions(userMood);
    } catch (e) {
      print('Error generating activity suggestions: $e');
      return _getDefaultActivitySuggestions(userMood);
    }
  }

  List<String> _getDefaultActivitySuggestions(String mood) {
    switch (mood.toLowerCase()) {
      case 'sad':
        return [
          'Let\'s share some happy memories',
          'How about we do a quick breathing exercise together?',
          'Want to talk about something that makes you smile?',
          'Let\'s play a simple word game to lift your spirits',
        ];
      case 'anxious':
        return [
          'Let\'s try a calming meditation exercise',
          'Want to talk through what\'s worrying you?',
          'How about we do some positive affirmations?',
          'Let\'s focus on something peaceful and relaxing',
        ];
      case 'happy':
        return [
          'Let\'s celebrate your good mood with a fun chat!',
          'Want to share what\'s making you happy today?',
          'How about we play a creative storytelling game?',
          'Let\'s talk about your dreams and goals!',
        ];
      default:
        return [
          'Let\'s have a friendly conversation',
          'Want to play a simple game together?',
          'How about sharing what\'s on your mind?',
          'Let\'s do something fun and relaxing',
        ];
    }
  }

  Future<String> generatePersonalizedGreeting({
    required VirtualFriend friend,
    required String userName,
    String? timeOfDay,
    String? userMood,
    DateTime? lastChatTime,
  }) async {
    try {
      final timeSinceLastChat = lastChatTime != null 
          ? DateTime.now().difference(lastChatTime).inHours 
          : 999;

      final prompt = '''
As ${friend.name}, create a warm, personalized greeting for $userName.
Time of day: ${timeOfDay ?? 'unknown'}
User's mood: ${userMood ?? 'unknown'}
Hours since last chat: $timeSinceLastChat

Be friendly, supportive, and match your personality: ${friend.personality}
Keep it conversational and welcoming (1-2 sentences).
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 100,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? _getDefaultGreeting(friend, userName);
          }
        }
      }

      return _getDefaultGreeting(friend, userName);
    } catch (e) {
      print('Error generating greeting: $e');
      return _getDefaultGreeting(friend, userName);
    }
  }

  String _getDefaultGreeting(VirtualFriend friend, String userName) {
    final greetings = [
      "Hi $userName! Great to see you again! How are you doing today? 😊",
      "Hey there, $userName! I've been looking forward to our chat. What's new with you?",
      "Hello $userName! Hope you're having a wonderful day. What would you like to talk about?",
    ];
    
    greetings.shuffle();
    return greetings.first;
  }
}