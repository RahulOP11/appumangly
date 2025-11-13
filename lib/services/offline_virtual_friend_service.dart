import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/virtual_friend_models.dart';
import 'gemini_ai_service.dart';

/// Offline-first Virtual Friend service that works without Firebase
/// This is a fallback service when Firebase is unavailable
class OfflineVirtualFriendService {
  static const String _kFriendsKey = 'offline_virtual_friends';
  static const String _kChatPrefix = 'offline_chat_';
  static const String _kPreferredKey = 'preferred_friend_offline';

  final GeminiAIService _aiService = GeminiAIService();

  // Default virtual friends
  static final List<VirtualFriend> _defaultFriends = [
    VirtualFriend(
      id: 'meera_offline',
      name: 'Meera',
      gender: 'female',
      avatarAsset: 'assets/avatars/meera_avatar.png',
      personality: 'Warm, empathetic, and nurturing. Meera is a great listener who loves to offer emotional support and practical advice. She\'s optimistic and always looks for the bright side of things.',
      backstory: 'Meera grew up in a small town where community and caring for others were deeply valued. She studied psychology and loves helping people work through their feelings and find their inner strength.',
      interests: ['mindfulness', 'cooking', 'reading', 'nature walks', 'photography', 'journaling'],
      voiceType: VoiceType.warm,
      mood: FriendMood.cheerful,
      isActive: true,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    ),
    VirtualFriend(
      id: 'arav_offline',
      name: 'Arav',
      gender: 'male',
      avatarAsset: 'assets/avatars/arav_avatar.png',
      personality: 'Adventurous, motivational, and energetic. Arav is your go-to friend for encouragement and inspiration. He loves challenges and helps you see opportunities in every situation.',
      backstory: 'Arav is a former athlete turned life coach who believes in the power of perseverance and positive thinking. He\'s traveled the world and has many exciting stories to share.',
      interests: ['fitness', 'travel', 'music', 'technology', 'sports', 'motivational content'],
      voiceType: VoiceType.energetic,
      mood: FriendMood.excited,
      isActive: true,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    ),
  ];

  // Get all available virtual friends
  Future<List<VirtualFriend>> getAvailableFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString(_kFriendsKey);
      
      if (friendsJson != null) {
        final friendsList = jsonDecode(friendsJson) as List;
        return friendsList
            .map((json) => VirtualFriend.fromMap(json))
            .toList();
      }

      // Initialize with default friends
      await _saveFriends(_defaultFriends);
      return _defaultFriends;
    } catch (e) {
      print('Error loading offline friends: $e');
      return _defaultFriends;
    }
  }

  // Save friends list
  Future<void> _saveFriends(List<VirtualFriend> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = jsonEncode(friends.map((f) => f.toMap()).toList());
      await prefs.setString(_kFriendsKey, friendsJson);
    } catch (e) {
      print('Error saving offline friends: $e');
    }
  }

  // Get a specific friend by ID
  Future<VirtualFriend?> getFriend(String friendId) async {
    try {
      final friends = await getAvailableFriends();
      return friends.where((f) => f.id == friendId).firstOrNull;
    } catch (e) {
      print('Error getting offline friend: $e');
      return _defaultFriends.where((f) => f.id == friendId).firstOrNull;
    }
  }

  // Get chat session for a friend
  Future<ChatSession?> getChatSession(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = '$_kChatPrefix$friendId';
      final chatJson = prefs.getString(chatKey);

      if (chatJson != null) {
        final chatData = jsonDecode(chatJson);
        return ChatSession.fromMap(chatData);
      }

      // Create new session
      final newSession = ChatSession(
        id: friendId,
        friendId: friendId,
        userId: 'offline_user',
        messages: <ChatMessage>[],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        isActive: true,
        context: <String, dynamic>{},
      );

      await _saveChatSession(newSession);
      return newSession;
    } catch (e) {
      print('Error getting offline chat session: $e');
      return null;
    }
  }

  // Save chat session
  Future<void> _saveChatSession(ChatSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = '$_kChatPrefix${session.friendId}';
      final chatJson = jsonEncode(session.toMap());
      await prefs.setString(chatKey, chatJson);
    } catch (e) {
      print('Error saving offline chat session: $e');
    }
  }

  // Send message to virtual friend
  Future<ChatMessage?> sendMessage({
    required String friendId,
    required String userMessage,
    String? userMood,
    Map<String, dynamic>? context,
  }) async {
    try {
      final friend = await getFriend(friendId);
      if (friend == null) return null;

      final session = await getChatSession(friendId);
      if (session == null) return null;

      // Create user message
      final userChatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: session.id,
        message: userMessage,
        isFromUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      // Add user message to session
      session.messages.add(userChatMessage);

      // Generate AI response
      final aiResponse = await _aiService.generateFriendResponse(
        friend: friend,
        userMessage: userMessage,
        conversationHistory: session.messages,
        userMood: userMood,
        context: context,
      );

      // Create AI response message
      final aiChatMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sessionId: session.id,
        message: aiResponse,
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: MessageType.text,
      );

      // Add AI message to session
      session.messages.add(aiChatMessage);

      // Update session with new last message time
      final updatedSession = session.copyWith(
        messages: session.messages,
        lastMessageAt: DateTime.now(),
      );

      // Save updated session
      await _saveChatSession(updatedSession);

      return aiChatMessage;
    } catch (e) {
      print('Error sending offline message: $e');
      return null;
    }
  }

  // Get recent chat sessions
  Future<List<ChatSession>> getRecentChatSessions({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys()
          .where((key) => key.startsWith(_kChatPrefix))
          .toList();

      final sessions = <ChatSession>[];
      
      for (final key in keys) {
        final chatJson = prefs.getString(key);
        if (chatJson != null) {
          try {
            final chatData = jsonDecode(chatJson);
            final session = ChatSession.fromMap(chatData);
            sessions.add(session);
          } catch (e) {
            print('Error parsing offline session $key: $e');
          }
        }
      }

      // Sort by last message time
      sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      
      return sessions.take(limit).toList();
    } catch (e) {
      print('Error getting offline recent sessions: $e');
      return <ChatSession>[];
    }
  }

  // Get activity suggestions from AI
  Future<List<String>> getActivitySuggestions({
    required String friendId,
    required String userMood,
    List<String>? userInterests,
  }) async {
    try {
      final friend = await getFriend(friendId);
      if (friend == null) return [];

      return await _aiService.generateActivitySuggestions(
        friend: friend,
        userMood: userMood,
        userInterests: userInterests,
      );
    } catch (e) {
      print('Error getting offline activity suggestions: $e');
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
        ];
      case 'anxious':
        return [
          'Let\'s try a calming meditation exercise',
          'Want to talk through what\'s worrying you?',
          'How about we do some positive affirmations?',
        ];
      case 'happy':
        return [
          'Let\'s celebrate your good mood with a fun chat!',
          'Want to share what\'s making you happy today?',
          'How about we play a creative storytelling game?',
        ];
      default:
        return [
          'Let\'s have a friendly conversation',
          'Want to play a simple game together?',
          'How about sharing what\'s on your mind?',
        ];
    }
  }

  // Get personalized greeting
  Future<String> getPersonalizedGreeting({
    required String friendId,
    String? userName,
    String? userMood,
  }) async {
    try {
      final friend = await getFriend(friendId);
      if (friend == null) return 'Hello! Great to see you today! 😊';

      return await _aiService.generatePersonalizedGreeting(
        friend: friend,
        userName: userName ?? 'friend',
        timeOfDay: DateTime.now().hour < 12 ? 'morning' : DateTime.now().hour < 17 ? 'afternoon' : 'evening',
        userMood: userMood,
        lastChatTime: null,
      );
    } catch (e) {
      print('Error getting offline greeting: $e');
      return 'Hello! Great to see you today! 😊';
    }
  }

  // Clear chat history
  Future<void> clearChatHistory(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatKey = '$_kChatPrefix$friendId';
      await prefs.remove(chatKey);
      
      // Create fresh session
      final newSession = ChatSession(
        id: friendId,
        friendId: friendId,
        userId: 'offline_user',
        messages: <ChatMessage>[],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        isActive: true,
      );
      
      await _saveChatSession(newSession);
    } catch (e) {
      print('Error clearing offline chat history: $e');
    }
  }

  // Get/Set preferred friend
  Future<String?> getPreferredFriend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kPreferredKey);
    } catch (e) {
      print('Error getting offline preferred friend: $e');
      return null;
    }
  }

  Future<void> setPreferredFriend(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPreferredKey, friendId);
    } catch (e) {
      print('Error setting offline preferred friend: $e');
    }
  }

  // Update friend activity (no-op for offline)
  Future<void> updateFriendActivity(String friendId) async {
    // No-op for offline mode
    print('Offline mode: Friend activity updated for $friendId');
  }

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      final sessions = await getRecentChatSessions(limit: 100);
      
      final totalSessions = sessions.length;
      final totalMessages = sessions.fold<int>(
        0, 
        (sum, session) => sum + session.messages.length,
      );
      
      final activeFriends = sessions.map((s) => s.friendId).toSet().length;
      
      final lastChatDate = sessions.isNotEmpty 
          ? sessions.first.lastMessageAt 
          : null;

      return {
        'totalSessions': totalSessions,
        'totalMessages': totalMessages,
        'activeFriends': activeFriends,
        'lastChatDate': lastChatDate?.toIso8601String(),
        'mode': 'offline',
      };
    } catch (e) {
      print('Error getting offline chat statistics: $e');
      return {'mode': 'offline'};
    }
  }
}