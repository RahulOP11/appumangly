// Enums
enum MessageType { text, image, audio, activity }
enum FriendMood { happy, excited, calm, thoughtful, playful, cheerful }
enum ActivityType { conversation, game, meditation, exercise, creative }
enum VoiceType { warm, energetic, calm, playful, gentle }

// Virtual Friend Model
class VirtualFriend {
  final String id;
  final String name;
  final String gender;
  final String avatarAsset;
  final String personality;
  final String backstory;
  final List<String> interests;
  final VoiceType voiceType;
  final FriendMood mood;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final Map<String, dynamic> customization;

  const VirtualFriend({
    required this.id,
    required this.name,
    required this.gender,
    required this.avatarAsset,
    required this.personality,
    required this.backstory,
    required this.interests,
    required this.voiceType,
    required this.mood,
    required this.isActive,
    required this.createdAt,
    required this.lastActiveAt,
    this.customization = const {},
  });

  factory VirtualFriend.fromMap(Map<String, dynamic> map) {
    return VirtualFriend(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      avatarAsset: map['avatarAsset']?.toString() ?? '',
      personality: map['personality']?.toString() ?? '',
      backstory: map['backstory']?.toString() ?? '',
      interests: map['interests'] != null 
          ? List<String>.from((map['interests'] as List).map((e) => e?.toString() ?? ''))
          : <String>[],
      voiceType: VoiceType.values.firstWhere(
        (type) => type.name == map['voiceType']?.toString(),
        orElse: () => VoiceType.warm,
      ),
      mood: FriendMood.values.firstWhere(
        (mood) => mood.name == map['mood']?.toString(),
        orElse: () => FriendMood.happy,
      ),
      isActive: map['isActive'] == true,
      createdAt: _parseDateTime(map['createdAt']),
      lastActiveAt: _parseDateTime(map['lastActiveAt']),
      customization: map['customization'] != null 
          ? Map<String, dynamic>.from(map['customization'] as Map)
          : <String, dynamic>{},
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'avatarAsset': avatarAsset,
      'personality': personality,
      'backstory': backstory,
      'interests': interests,
      'voiceType': voiceType.name,
      'mood': mood.name,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
      'customization': customization,
    };
  }

  VirtualFriend copyWith({
    String? id,
    String? name,
    String? gender,
    String? avatarAsset,
    String? personality,
    String? backstory,
    List<String>? interests,
    VoiceType? voiceType,
    FriendMood? mood,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    Map<String, dynamic>? customization,
  }) {
    return VirtualFriend(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      personality: personality ?? this.personality,
      backstory: backstory ?? this.backstory,
      interests: interests ?? this.interests,
      voiceType: voiceType ?? this.voiceType,
      mood: mood ?? this.mood,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      customization: customization ?? this.customization,
    );
  }
}

// Chat Message Model
class ChatMessage {
  final String id;
  final String sessionId;
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType messageType;
  final String? emotion;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    required this.messageType,
    this.emotion,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      isFromUser: map['isFromUser'] == true,
      timestamp: VirtualFriend._parseDateTime(map['timestamp']),
      messageType: MessageType.values.firstWhere(
        (type) => type.name == map['messageType']?.toString(),
        orElse: () => MessageType.text,
      ),
      emotion: map['emotion']?.toString(),
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'message': message,
      'isFromUser': isFromUser,
      'timestamp': timestamp,
      'messageType': messageType.name,
      'emotion': emotion,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? message,
    bool? isFromUser,
    DateTime? timestamp,
    MessageType? messageType,
    String? emotion,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      message: message ?? this.message,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      emotion: emotion ?? this.emotion,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Chat Session Model
class ChatSession {
  final String id;
  final String friendId;
  final String userId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final Map<String, dynamic> context;

  const ChatSession({
    required this.id,
    required this.friendId,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isActive,
    this.context = const {},
  });

  factory ChatSession.fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id']?.toString() ?? '',
      friendId: map['friendId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      messages: map['messages'] != null
          ? (map['messages'] as List<dynamic>)
              .map((msg) => ChatMessage.fromMap(
                  msg is Map<String, dynamic> ? msg : <String, dynamic>{}))
              .toList()
          : <ChatMessage>[],
      createdAt: VirtualFriend._parseDateTime(map['createdAt']),
      lastMessageAt: VirtualFriend._parseDateTime(map['lastMessageAt']),
      isActive: map['isActive'] == true,
      context: map['context'] != null 
          ? Map<String, dynamic>.from(map['context'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'friendId': friendId,
      'userId': userId,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'createdAt': createdAt,
      'lastMessageAt': lastMessageAt,
      'isActive': isActive,
      'context': context,
    };
  }

  ChatSession copyWith({
    String? id,
    String? friendId,
    String? userId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isActive,
    Map<String, dynamic>? context,
  }) {
    return ChatSession(
      id: id ?? this.id,
      friendId: friendId ?? this.friendId,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      context: context ?? this.context,
    );
  }
}