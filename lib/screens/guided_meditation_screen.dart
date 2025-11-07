import 'package:flutter/material.dart';
import '../models/meditation_models.dart';
import '../services/meditation_data_service.dart';

class GuidedMeditationScreen extends StatefulWidget {
  const GuidedMeditationScreen({super.key});

  @override
  State<GuidedMeditationScreen> createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen> {
  List<MeditationSession> _sessions = [];
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Stress Relief',
    'Anxiety',
    'Focus',
    'Sleep',
    'Relaxation',
    'Emotional',
    'Mindfulness'
  ];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessions = MeditationDataService.getFreeMeditationSessions();
    });
  }

  List<MeditationSession> get _filteredSessions {
    if (_selectedCategory == 'All') {
      return _sessions;
    }
    return _sessions.where((session) => session.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildSessionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFF667eea) 
                        : Colors.white,
                    fontWeight: isSelected 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredSessions.length,
      itemBuilder: (context, index) {
        final session = _filteredSessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(MeditationSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(session.title)),
                body: Center(
                  child: Text('Meditation Player - ${session.title}'),
                ),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getCategoryColors(session.category),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(session.category),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session.duration,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(session.difficulty),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            session.difficulty,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_fill,
                color: Color(0xFF667eea),
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryColors(String category) {
    switch (category) {
      case 'Stress Relief':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'Anxiety':
        return [const Color(0xFF48CAE4), const Color(0xFF0077B6)];
      case 'Focus':
        return [const Color(0xFF00B4DB), const Color(0xFF0083B0)];
      case 'Sleep':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'Relaxation':
        return [const Color(0xFF11998E), const Color(0xFF38EF7D)];
      case 'Emotional':
        return [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)];
      case 'Mindfulness':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Stress Relief':
        return Icons.spa;
      case 'Anxiety':
        return Icons.favorite;
      case 'Focus':
        return Icons.center_focus_strong;
      case 'Sleep':
        return Icons.nightlight_round;
      case 'Relaxation':
        return Icons.self_improvement;
      case 'Emotional':
        return Icons.mood;
      case 'Mindfulness':
        return Icons.psychology;
      default:
        return Icons.self_improvement;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}