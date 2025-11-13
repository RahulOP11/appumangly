import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/virtual_friend_models.dart';
import 'gemini_ai_service.dart';
import 'dialogflow_service.dart';

class VirtualFriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GeminiAIService _aiService = GeminiAIService();
  final DialogflowService _dialogflowService = DialogflowService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Default virtual friends
  static final List<VirtualFriend> _defaultFriends = [
    VirtualFriend(
      id: 'meera_friend',
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
      id: 'arav_friend',
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
      if (_currentUserId == null) {
        print('No authenticated user, returning default friends');
        return _defaultFriends;
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('virtualFriends')
          .where('isActive', isEqualTo: true)
          .orderBy('lastActiveAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No friends found in Firestore, initializing defaults');
        await _initializeDefaultFriends();
        return _defaultFriends;
      }

      final friends = <VirtualFriend>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          if (data.isNotEmpty) {
            friends.add(VirtualFriend.fromMap(data));
          }
        } catch (e) {
          print('Error parsing friend document ${doc.id}: $e');
          // Skip this document and continue
        }
      }

      return friends.isNotEmpty ? friends : _defaultFriends;
    } catch (e) {
      print('Error getting available friends: $e');
      return _defaultFriends;
    }
  }

  // Initialize default friends for new users
  Future<void> _initializeDefaultFriends() async {
    if (_currentUserId == null) {
      print('Cannot initialize friends: no authenticated user');
      return;
    }

    try {
      final batch = _firestore.batch();
      final userFriendsRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('virtualFriends');

      for (final friend in _defaultFriends) {
        final friendData = friend.toMap();
        // Ensure all required fields are present
        friendData['createdAt'] = FieldValue.serverTimestamp();
        friendData['lastActiveAt'] = FieldValue.serverTimestamp();
        batch.set(userFriendsRef.doc(friend.id), friendData);
      }

      await batch.commit();
      print('Default friends initialized successfully');
    } catch (e) {
      print('Error initializing default friends: $e');
    }
  }

  // Get a specific friend by ID
  Future<VirtualFriend?> getFriend(String friendId) async {
    try {
      if (_currentUserId == null) {
        return _defaultFriends.firstWhere(
          (f) => f.id == friendId,
          orElse: () => _defaultFriends.first,
        );
      }

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('virtualFriends')
          .doc(friendId)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          return VirtualFriend.fromMap(doc.data()!);
        } catch (e) {
          print('Error parsing friend document: $e');
          // Fall through to default friends
        }
      }

      // Fallback to default friends
      final defaultFriend = _defaultFriends.where((f) => f.id == friendId).firstOrNull;
      return defaultFriend ?? _defaultFriends.first;
    } catch (e) {
      print('Error getting friend: $e');
      return _defaultFriends.isNotEmpty ? _defaultFriends.first : null;
    }
  }

  // Update friend's last active time
  Future<void> updateFriendActivity(String friendId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('virtualFriends')
          .doc(friendId)
          .update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating friend activity: $e');
    }
  }

  // Get chat session for a friend
  Future<ChatSession?> getChatSession(String friendId) async {
    try {
      if (_currentUserId == null) {
        print('No authenticated user for chat session');
        // Create an offline session as fallback
        return _createOfflineSession(friendId);
      }

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .doc(friendId)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          return ChatSession.fromMap(doc.data()!);
        } catch (e) {
          print('Error parsing chat session: $e');
          // Create new session on parse error
        }
      }

      // Create new session
      final newSession = ChatSession(
        id: friendId,
        friendId: friendId,
        userId: _currentUserId!,
        messages: <ChatMessage>[],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        isActive: true,
        context: <String, dynamic>{},
      );

      final sessionData = newSession.toMap();
      sessionData['createdAt'] = FieldValue.serverTimestamp();
      sessionData['lastMessageAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .doc(friendId)
          .set(sessionData);

      return newSession;
    } catch (e) {
      print('Error getting chat session: $e, creating offline session');
      // Create offline session as fallback
      return _createOfflineSession(friendId);
    }
  }

  // Create offline session for when Firebase is unavailable
  ChatSession _createOfflineSession(String friendId) {
    return ChatSession(
      id: '${friendId}_offline',
      friendId: friendId,
      userId: 'offline_user',
      messages: <ChatMessage>[],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      isActive: true,
      context: <String, dynamic>{'mode': 'offline'},
    );
  }

  // Send message to virtual friend
  Future<ChatMessage?> sendMessage({
    required String friendId,
    required String userMessage,
    String? userMood,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (_currentUserId == null) return null;

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

      // Generate AI response - use Dialogflow for Arav, Gemini for others
      String aiResponse;
      if (friend.name.toLowerCase() == 'arav') {
        // Use Dialogflow for Arav
        final sessionId = 'user_${_currentUserId}_friend_${friendId}';
        aiResponse = await _dialogflowService.detectIntent(
          sessionId: sessionId,
          text: userMessage,
          friend: friend,
        );
      } else {
        // Use Gemini for other friends
        aiResponse = await _aiService.generateFriendResponse(
          friend: friend,
          userMessage: userMessage,
          conversationHistory: session.messages,
          userMood: userMood,
          context: context,
        );
      }

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

      // Save updated session
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .doc(friendId)
          .update({
        'messages': session.messages.map((m) => m.toMap()).toList(),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      // Update friend activity
      await updateFriendActivity(friendId);

      return aiChatMessage;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Get recent chat sessions
  Future<List<ChatSession>> getRecentChatSessions({int limit = 10}) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ChatSession.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting recent chat sessions: $e');
      return [];
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
      print('Error getting activity suggestions: $e');
      return [];
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

      final session = await getChatSession(friendId);
      final lastChatTime = session?.lastMessageAt;

      final now = DateTime.now();
      final timeOfDay = now.hour < 12 
          ? 'morning' 
          : now.hour < 17 
              ? 'afternoon' 
              : 'evening';

      return await _aiService.generatePersonalizedGreeting(
        friend: friend,
        userName: userName ?? 'friend',
        timeOfDay: timeOfDay,
        userMood: userMood,
        lastChatTime: lastChatTime,
      );
    } catch (e) {
      print('Error getting personalized greeting: $e');
      return 'Hello! Great to see you today! 😊';
    }
  }

  // Delete chat session
  Future<void> deleteChatSession(String friendId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .doc(friendId)
          .delete();
    } catch (e) {
      print('Error deleting chat session: $e');
    }
  }

  // Clear all messages in a chat session
  Future<void> clearChatHistory(String friendId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('chatSessions')
          .doc(friendId)
          .update({
        'messages': [],
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error clearing chat history: $e');
    }
  }

  // Get user's preferred friend
  Future<String?> getPreferredFriend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('preferred_friend_id');
    } catch (e) {
      print('Error getting preferred friend: $e');
      return null;
    }
  }

  // Set user's preferred friend
  Future<void> setPreferredFriend(String friendId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_friend_id', friendId);
    } catch (e) {
      print('Error setting preferred friend: $e');
    }
  }

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics() async {
    try {
      if (_currentUserId == null) return {};

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
      };
    } catch (e) {
      print('Error getting chat statistics: $e');
      return {};
    }
  }
}