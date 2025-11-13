import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/virtual_friend_models.dart';
import '../services/virtual_friend_service.dart';

class VirtualFriendChatScreen extends StatefulWidget {
  final VirtualFriend friend;

  const VirtualFriendChatScreen({
    super.key,
    required this.friend,
  });

  @override
  State<VirtualFriendChatScreen> createState() => _VirtualFriendChatScreenState();
}

class _VirtualFriendChatScreenState extends State<VirtualFriendChatScreen>
    with TickerProviderStateMixin {
  final VirtualFriendService _friendService = VirtualFriendService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatSession? _currentSession;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  String? _userMood;
  List<String> _activitySuggestions = [];
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadChatSession();
    _loadGreeting();
    _loadActivitySuggestions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_typingAnimationController);
  }

  Future<void> _loadChatSession() async {
    setState(() => _isLoading = true);
    try {
      print('Loading chat session for friend: ${widget.friend.id}');
      final session = await _friendService.getChatSession(widget.friend.id);
      if (mounted) {
        setState(() {
          _currentSession = session ?? _createEmptySession();
          _isLoading = false;
        });
        _scrollToBottom();
        
        // Load greeting if this is a new session
        if (_currentSession?.messages.isEmpty == true) {
          _loadGreeting();
        }
      }
    } catch (e) {
      print('Error loading chat session: $e');
      if (mounted) {
        setState(() {
          _currentSession = _createEmptySession();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chat: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadChatSession,
            ),
          ),
        );
      }
    }
  }

  ChatSession _createEmptySession() {
    return ChatSession(
      id: '${widget.friend.id}_temp',
      friendId: widget.friend.id,
      userId: 'temp_user',
      messages: <ChatMessage>[],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      isActive: true,
      context: <String, dynamic>{'mode': 'temp'},
    );
  }

  Future<void> _loadGreeting() async {
    if (_currentSession?.messages.isEmpty == true) {
      final greeting = await _friendService.getPersonalizedGreeting(
        friendId: widget.friend.id,
        userName: 'friend', // You can customize this
        userMood: _userMood,
      );
      
      if (mounted && greeting.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _addAIMessage(greeting);
      }
    }
  }

  Future<void> _loadActivitySuggestions() async {
    if (_userMood != null) {
      final suggestions = await _friendService.getActivitySuggestions(
        friendId: widget.friend.id,
        userMood: _userMood!,
      );
      setState(() => _activitySuggestions = suggestions);
    }
  }

  Future<void> _addAIMessage(String message) async {
    if (_currentSession == null) return;

    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession?.id ?? 'temp_session',
      message: message,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
    );

    setState(() {
      _currentSession?.messages.add(aiMessage);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) {
      print('Cannot send message: empty text or already sending');
      return;
    }

    // Ensure we have a session
    if (_currentSession == null) {
      print('No current session, creating one');
      _currentSession = _createEmptySession();
    }

    final userMessage = _messageController.text.trim();
    _messageController.clear();
    
    setState(() => _isSending = true);

    // Add user message immediately
    final userChatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: _currentSession?.id ?? 'temp_session',
      message: userMessage,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: MessageType.text,
    );

    setState(() {
      _currentSession?.messages.add(userChatMessage);
      _isTyping = true;
    });
    
    _typingAnimationController.repeat();
    _scrollToBottom();

    try {
      print('Sending message to friend: ${widget.friend.name}');
      // Send message and get AI response
      final aiMessage = await _friendService.sendMessage(
        friendId: widget.friend.id,
        userMessage: userMessage,
        userMood: _userMood,
        context: _buildConversationContext(),
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _isSending = false;
        });
        _typingAnimationController.stop();

        if (aiMessage != null) {
          print('Received AI response, reloading session');
          // The service already adds the AI message to the session
          await _loadChatSession(); // Reload to get updated session
        } else {
          print('No AI response received');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No response received. Please try again.')),
            );
          }
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        setState(() {
          _isTyping = false;
          _isSending = false;
        });
        _typingAnimationController.stop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _messageController.text = userMessage;
                _sendMessage();
              },
            ),
          ),
        );
      }
    }
  }

  Map<String, dynamic> _buildConversationContext() {
    return {
      'screen': 'chat',
      'time_of_day': _getTimeOfDay(),
      'conversation_length': _currentSession?.messages.length ?? 0,
      'user_mood': _userMood,
    };
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.friend.gender.toLowerCase() == 'female' 
                  ? Colors.pink[100] 
                  : Colors.blue[100],
              child: Icon(
                widget.friend.gender.toLowerCase() == 'female' 
                    ? Icons.face_3 
                    : Icons.face,
                color: widget.friend.gender.toLowerCase() == 'female' 
                    ? Colors.pink[600] 
                    : Colors.blue[600],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Virtual Friend • Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple[100],
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mood',
                child: Row(
                  children: [
                    Icon(Icons.mood, size: 18),
                    SizedBox(width: 8),
                    Text('Set Mood'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'activities',
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Activities'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18),
                    SizedBox(width: 8),
                    Text('Clear Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Friend Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildChatInterface(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.purple[400]),
          const SizedBox(height: 16),
          Text(
            'Setting up your chat with ${widget.friend.name}...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.purple[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        if (_activitySuggestions.isNotEmpty) _buildActivitySuggestions(),
        Expanded(child: _buildMessagesList()),
        if (_isTyping) _buildTypingIndicator(),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildActivitySuggestions() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        border: Border(
          bottom: BorderSide(color: Colors.purple[100]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Suggestions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple[800],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activitySuggestions.length,
              itemBuilder: (context, index) => _buildActivityChip(
                _activitySuggestions[index],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChip(String activity) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          activity,
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () => _selectActivity(activity),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.purple[200]!),
      ),
    );
  }

  void _selectActivity(String activity) {
    _messageController.text = activity;
    setState(() => _activitySuggestions = []);
    _sendMessage();
  }

  Widget _buildMessagesList() {
    if (_currentSession?.messages.isEmpty == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: widget.friend.gender.toLowerCase() == 'female' 
                  ? Colors.pink[100] 
                  : Colors.blue[100],
              child: Icon(
                widget.friend.gender.toLowerCase() == 'female' 
                    ? Icons.face_3 
                    : Icons.face,
                size: 50,
                color: widget.friend.gender.toLowerCase() == 'female' 
                    ? Colors.pink[600] 
                    : Colors.blue[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hello to ${widget.friend.name}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.purple[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your conversation with your virtual friend.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentSession?.messages.length ?? 0,
      itemBuilder: (context, index) => _buildMessageBubble(
        _currentSession?.messages[index] ?? ChatMessage(
          id: 'error',
          sessionId: 'error',
          message: 'Message not available',
          isFromUser: false,
          timestamp: DateTime.now(),
          messageType: MessageType.text,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isFromUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.friend.gender.toLowerCase() == 'female' 
                  ? Colors.pink[100] 
                  : Colors.blue[100],
              child: Icon(
                widget.friend.gender.toLowerCase() == 'female' 
                    ? Icons.face_3 
                    : Icons.face,
                size: 20,
                color: widget.friend.gender.toLowerCase() == 'female' 
                    ? Colors.pink[600] 
                    : Colors.blue[600],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Colors.purple[400] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple[100],
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.purple[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.friend.gender.toLowerCase() == 'female' 
                ? Colors.pink[100] 
                : Colors.blue[100],
            child: Icon(
              widget.friend.gender.toLowerCase() == 'female' 
                  ? Icons.face_3 
                  : Icons.face,
              size: 20,
              color: widget.friend.gender.toLowerCase() == 'female' 
                  ? Colors.pink[600] 
                  : Colors.blue[600],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400]?.withOpacity(
                          ((_typingAnimation.value + index * 0.3) % 1.0).clamp(0.3, 1.0)
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message to ${widget.friend.name}...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.purple[400]!),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.purple[400],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mood':
        _showMoodSelector();
        break;
      case 'activities':
        _showActivityDialog();
        break;
      case 'clear':
        _confirmClearChat();
        break;
      case 'info':
        _showFriendInfo();
        break;
    }
  }

  void _showMoodSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How are you feeling?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: ['happy', 'sad', 'anxious', 'excited', 'calm', 'tired']
                  .map((mood) => ActionChip(
                    label: Text(mood),
                    onPressed: () {
                      setState(() => _userMood = mood);
                      Navigator.pop(context);
                      _loadActivitySuggestions();
                    },
                    backgroundColor: _userMood == mood 
                        ? Colors.purple[100] 
                        : null,
                  ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Suggestions'),
        content: _activitySuggestions.isEmpty
            ? const Text('Set your mood first to get personalized activity suggestions!')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _activitySuggestions.map((activity) =>
                  ListTile(
                    title: Text(activity),
                    onTap: () {
                      Navigator.pop(context);
                      _selectActivity(activity);
                    },
                  ),
                ).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to clear all messages with this friend? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _friendService.clearChatHistory(widget.friend.id);
              await _loadChatSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showFriendInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.friend.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Gender', widget.friend.gender),
              _buildInfoRow('Voice Type', widget.friend.voiceType.name),
              _buildInfoRow('Current Mood', widget.friend.mood.name),
              const SizedBox(height: 12),
              const Text('Personality:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.friend.personality),
              const SizedBox(height: 12),
              const Text('Backstory:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(widget.friend.backstory),
              const SizedBox(height: 12),
              const Text('Interests:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: widget.friend.interests.map((interest) => Chip(
                  label: Text(interest, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}