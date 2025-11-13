import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import 'meditation_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'simple_emotion_webview_screen.dart';
import 'diary_screen.dart';
import 'virtual_friend_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Home - already on home
        break;
      case 1:
        // Activities - can add activities screen later
        break;
      case 2:
        // Journal - navigate to diary
        _navigateToDiary();
        break;
      case 3:
        // Profile - can add profile screen later
        break;
    }
  }

  void _navigateToDiary() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiaryScreen(),
      ),
    );
    // Reset selection when returning
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _navigateToVirtualFriend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VirtualFriendScreen(),
      ),
    );
    // Reset selection when returning
    setState(() {
      _selectedIndex = 0;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSmileInstructionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('😊', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('Smile Challenge'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎯 Your Mission:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'You need to smile 3 times to boost your mood and set your day right!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                '🌐 This will open in your browser where the camera works perfectly!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openEmotionDetectionWebView(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sentiment_very_satisfied, size: 16),
                  SizedBox(width: 4),
                  Text("Start Smiling!"),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEmotionDetectionWebView(BuildContext context) async {
    try {
      const urlString = 'https://emotion-wine.vercel.app/';
      final uri = Uri.parse(urlString);
      
      // Try different launch modes for better compatibility
      bool launched = false;
      
      // Try external application first
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('External app launch failed: $e');
      }
      
      // If external app failed, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }
      
      // If both failed, try in-app browser (WebView with return button)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppBrowserView,
          );
        } catch (e) {
          print('In-app browser launch failed, trying WebView: $e');
        }
      }
      
      // If all URL launching failed, use our custom WebView with return button
      if (!launched) {
        print('All URL launch methods failed, using custom WebView');
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SimpleEmotionWebViewScreen(
              url: Uri.parse('https://emotion-wine.vercel.app/'),
            ),
          ),
        );
        
        // Handle the result when user comes back from WebView
        if (result != null && result is Map && context.mounted) {
          if (result['emotion_smiles_completed'] == true) {
            final smileCount = result['count'] ?? 3;
            _showCongratulationsDialog(context, smileCount);
          }
        }
        return;
      }
      
      if (launched) {
        // Show completion dialog after a short delay for external browser
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            _showManualCompletionOptions(context);
          }
        });
      } else {
        if (context.mounted) {
          _showErrorDialog(context);
        }
      }
    } catch (e) {
      print('Error opening emotion detection: $e');
      if (context.mounted) {
        _showErrorDialog(context);
      }
    }
  }

  void _showManualCompletionOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('✅', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('Completed?'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Did you complete your 3 smiles on the emotion detection page?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              Text(
                '😊 Click "Yes" when you\'ve finished to get your congratulations!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not Yet'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showCongratulationsDialog(context, 3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16),
                  SizedBox(width: 4),
                  Text('Yes, Done!'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCongratulationsDialog(BuildContext context, int smileCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('Congratulations!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      '✨ Your Mood is Set! ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'You completed $smileCount smiles!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '🌟 Amazing work! You\'ve taken a positive step for your mental wellness today. Keep spreading those beautiful smiles!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                '💝 Remember: Every smile makes the world a little brighter!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, size: 16),
                  SizedBox(width: 4),
                  Text('Continue Journey'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Text('⚠️', style: TextStyle(fontSize: 32)),
              SizedBox(width: 10),
              Text('URL Launch Issue'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unable to automatically open the emotion detection page.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'Please manually open this URL in your browser:',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  'https://emotion-wine.vercel.app/',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Copy and paste this URL into your browser, complete 3 smiles, then return here!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showManualCompletionOptions(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('I\'ll Do It Manually'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Welcome, ${user?.displayName?.split(' ').first ?? 'User'}!",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF667eea),
                child: Text(
                  (user?.displayName?.isNotEmpty ?? false)
                      ? user!.displayName![0].toUpperCase()
                      : user?.email?[0].toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.waving_hand, color: Colors.white, size: 32),
                      SizedBox(width: 8),
                      Text(
                        "You're all set!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your wellness journey starts here ✨",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Signed in as: ${user?.email}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 8),

            // Mood selector tab (How are you feeling today?)
            const MoodTab(),

            const SizedBox(height: 24),

            // Section Title
            const Text(
              "Wellness Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Feature Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                FeatureCard(
                  icon: Icons.psychology,
                  title: "Emotion Check",
                  subtitle: "AI emotion analysis first",
                  colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
                  onTap: () {
                    _showSmileInstructionDialog(context);
                  },
                ),
                FeatureCard(
                  icon: Icons.spa,
                  title: "Meditation",
                  subtitle: "Calm your mind",
                  colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MeditationScreen(),
                      ),
                    );
                  },
                ),
                const FeatureCard(
                  icon: Icons.format_quote,
                  title: "Affirmations",
                  subtitle: "Daily positivity",
                  colors: [Color(0xFFd299c2), Color(0xFFfef9d7)],
                ),
                const FeatureCard(
                  icon: Icons.visibility,
                  title: "Mind Tricks",
                  subtitle: "Stress relief",
                  colors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Additional Features
            FeatureListCard(
              icon: Icons.book,
              title: "AI Diary",
              subtitle: "Record your thoughts and feelings",
              color: Color(0xFF667eea),
              onTap: _navigateToDiary,
            ),
            const SizedBox(height: 12),
            FeatureListCard(
              icon: Icons.smart_toy,
              title: "Virtual Friend",
              subtitle: "AI-powered emotional companion",
              color: Color(0xFF764ba2),
              onTap: _navigateToVirtualFriend,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        elevation: 10,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Activities",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Journal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// Custom Feature Card Widget
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback? onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Feature List Card Widget
class FeatureListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const FeatureListCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

// Mood selector tab widget
class MoodTab extends StatefulWidget {
  const MoodTab({super.key});

  @override
  State<MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends State<MoodTab> {
  int _selectedIndex = -1;

  final List<_MoodOption> _options = const [
    _MoodOption(label: 'Great', icon: Icons.wb_sunny, color: Color(0xFFFFD866)),
    _MoodOption(label: 'Good', icon: Icons.sentiment_satisfied, color: Color(0xFF9AE6B4)),
    _MoodOption(label: 'Okay', icon: Icons.sentiment_neutral, color: Color(0xFFBFD4FF)),
    _MoodOption(label: 'Low', icon: Icons.cloud, color: Color(0xFFE6E6E6)),
    _MoodOption(label: 'Sad', icon: Icons.sentiment_dissatisfied, color: Color(0xFFE8DAF5)),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate to full mood selection screen for comprehensive mood tracking
    Navigator.pushNamed(context, '/mood-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling today?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 85,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final opt = _options[index];
                final selected = index == _selectedIndex;
                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 96,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFf3e8ff) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? const Color(0xFF764ba2) : Colors.grey.shade200,
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF764ba2).withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF764ba2) : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(opt.icon, size: 18, color: selected ? Colors.white : Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            color: selected ? const Color(0xFF764ba2) : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodOption {
  final String label;
  final IconData icon;
  final Color color;
  const _MoodOption({required this.label, required this.icon, required this.color});
}