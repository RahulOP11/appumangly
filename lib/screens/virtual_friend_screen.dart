import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/virtual_friend_models.dart';
import '../services/virtual_friend_service.dart';
import '../services/offline_virtual_friend_service.dart';
import 'virtual_friend_chat_screen.dart';

class VirtualFriendScreen extends StatefulWidget {
  const VirtualFriendScreen({super.key});

  @override
  State<VirtualFriendScreen> createState() => _VirtualFriendScreenState();
}

class _VirtualFriendScreenState extends State<VirtualFriendScreen> {
  final VirtualFriendService _friendService = VirtualFriendService();
  final OfflineVirtualFriendService _offlineService = OfflineVirtualFriendService();
  
  List<VirtualFriend> _friends = [];
  bool _isLoading = true;
  bool _isOfflineMode = false;
  String? _preferredFriendId;

  @override
  void initState() {
    super.initState();
    // Debug: Check Firebase Auth status
    final user = FirebaseAuth.instance.currentUser;
    print('VirtualFriendScreen: Current user: ${user?.uid ?? 'No user'}');
    print('VirtualFriendScreen: User email: ${user?.email ?? 'No email'}');
    
    _loadFriends();
    _loadPreferredFriend();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      print('Loading virtual friends...');
      
      // First try Firebase service
      try {
        final friends = await _friendService.getAvailableFriends();
        print('Loaded ${friends.length} friends from Firebase');
        if (mounted) {
          setState(() {
            _friends = friends;
            _isLoading = false;
            _isOfflineMode = false;
          });
        }
        return;
      } catch (firebaseError) {
        print('Firebase error, falling back to offline mode: $firebaseError');
        
        // Fall back to offline service
        final friends = await _offlineService.getAvailableFriends();
        print('Loaded ${friends.length} friends from offline storage');
        
        if (mounted) {
          setState(() {
            _friends = friends;
            _isLoading = false;
            _isOfflineMode = true;
          });
          
          // Show offline mode notice
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Running in offline mode'),
                ],
              ),
              backgroundColor: Colors.orange[100],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Critical error loading friends: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading friends: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadFriends,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadPreferredFriend() async {
    try {
      final preferredId = await _friendService.getPreferredFriend();
      if (mounted) {
        setState(() => _preferredFriendId = preferredId);
      }
    } catch (e) {
      print('Error loading preferred friend: $e');
      // Continue without preferred friend - not critical
    }
  }

  Future<void> _setPreferredFriend(String friendId) async {
    await _friendService.setPreferredFriend(friendId);
    setState(() => _preferredFriendId = friendId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Friends'),
        backgroundColor: Colors.purple[100],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildFriendsGrid(),
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
            'Loading your virtual friends...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.purple[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsGrid() {
    if (_friends.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            Text(
              'Choose Your Virtual Friend',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Each friend has a unique personality and can help you with different things.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0, // Increased to 1.0 to eliminate final overflow
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _friends.length,
              itemBuilder: (context, index) => _buildFriendCard(_friends[index]),
            ),
            const SizedBox(height: 24),
            _buildRecentChatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No virtual friends available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (user == null)
            Text(
              'Please make sure you are logged in',
              style: TextStyle(color: Colors.red[600]),
            )
          else
            Text(
              'Try refreshing or check your connection',
              style: TextStyle(color: Colors.grey[500]),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFriends,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
          if (user == null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.emoji_people,
              size: 40,
              color: Colors.purple[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Virtual Friends!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI companions are here to chat, support, and brighten your day.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(VirtualFriend friend) {
    final isPreferred = friend.id == _preferredFriendId;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPreferred 
            ? BorderSide(color: Colors.purple[400]!, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _startChatWithFriend(friend),
        child: Padding(
          padding: const EdgeInsets.all(8), // Minimal padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with star overlay if preferred
              SizedBox(
                height: 56, // Fixed height to control layout
                child: Stack(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 26, // Smaller radius
                        backgroundColor: friend.gender.toLowerCase() == 'female' 
                            ? Colors.pink[100] 
                            : Colors.blue[100],
                        child: Icon(
                          friend.gender.toLowerCase() == 'female' 
                              ? Icons.face_3 
                              : Icons.face,
                          size: 30, // Smaller icon
                          color: friend.gender.toLowerCase() == 'female' 
                              ? Colors.pink[600] 
                              : Colors.blue[600],
                        ),
                      ),
                    ),
                    if (isPreferred)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.purple[400],
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Name
              Text(
                friend.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              
              // Gender badge - inline
              Text(
                friend.gender.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  color: friend.gender.toLowerCase() == 'female' 
                      ? Colors.pink[600] 
                      : Colors.blue[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              
              // Personality - single line only
              Text(
                friend.personality.split(',').first.trim(),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              
              // Action buttons row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 24,
                      child: ElevatedButton(
                        onPressed: () => _startChatWithFriend(friend),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[400],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      onPressed: () => _setPreferredFriend(friend.id),
                      icon: Icon(
                        isPreferred ? Icons.star : Icons.star_outline,
                        size: 14,
                        color: Colors.purple[400],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Conversations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder(
          future: _friendService.getRecentChatSessions(limit: 3),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No recent conversations. Start chatting with a friend!',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((session) => 
                _buildRecentChatTile(session)
              ).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentChatTile(ChatSession session) {
    final friend = _friends.firstWhere(
      (f) => f.id == session.friendId,
      orElse: () => _friends.first,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: friend.gender.toLowerCase() == 'female' 
              ? Colors.pink[100] 
              : Colors.blue[100],
          child: Icon(
            friend.gender.toLowerCase() == 'female' 
                ? Icons.face_3 
                : Icons.face,
            color: friend.gender.toLowerCase() == 'female' 
                ? Colors.pink[600] 
                : Colors.blue[600],
          ),
        ),
        title: Text(friend.name),
        subtitle: Text(
          session.messages.isNotEmpty 
              ? session.messages.last.message
              : 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTime(session.lastMessageAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        onTap: () => _startChatWithFriend(friend),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _startChatWithFriend(VirtualFriend friend) {
    print('Starting chat with friend: ${friend.name} (${friend.id})');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VirtualFriendChatScreen(friend: friend),
        ),
      ).catchError((error) {
        print('Navigation error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening chat: $error')),
          );
        }
      });
    } catch (e) {
      print('Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  void _showFriendDetails(VirtualFriend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(friend.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Gender', friend.gender),
            _buildDetailRow('Voice Type', friend.voiceType.name),
            _buildDetailRow('Mood', friend.mood.name),
            const SizedBox(height: 12),
            const Text('Personality:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(friend.personality),
            const SizedBox(height: 12),
            const Text('Backstory:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(friend.backstory),
            const SizedBox(height: 12),
            const Text('Interests:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: friend.interests.map((interest) => Chip(
                label: Text(interest, style: const TextStyle(fontSize: 12)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startChatWithFriend(friend);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Virtual Friends'),
        content: const Text(
          'Virtual Friends are AI-powered companions designed to provide emotional support, '
          'engaging conversations, and mental wellness assistance. Each friend has a unique '
          'personality and can help you with different aspects of your day.\n\n'
          'Features:\n'
          '• Personalized conversations\n'
          '• Emotional support and guidance\n'
          '• Activity suggestions\n'
          '• 24/7 availability\n'
          '• Complete privacy and security',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}