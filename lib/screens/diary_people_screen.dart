import 'package:flutter/material.dart';
import '../models/diary_models.dart';
import '../services/diary_service.dart';

class DiaryPeopleScreen extends StatefulWidget {
  final DiaryService diaryService;

  const DiaryPeopleScreen({
    super.key,
    required this.diaryService,
  });

  @override
  State<DiaryPeopleScreen> createState() => _DiaryPeopleScreenState();
}

class _DiaryPeopleScreenState extends State<DiaryPeopleScreen> {
  List<PersonMention> _people = [];
  Map<String, int> _mentionCounts = {};
  List<ThankYouNote> _thankYouNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final people = await widget.diaryService.getAllPeopleMentioned();
      final counts = await widget.diaryService.getPeopleMentionCounts();
      final notes = await widget.diaryService.getAllThankYouNotes();
      
      setState(() {
        _people = people;
        _mentionCounts = counts;
        _thankYouNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'People'),
              Tab(text: 'Thank You Notes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPeopleTab(),
                _buildThankYouTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    if (_people.isEmpty) {
      return _buildEmptyPeopleState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _people.length,
      itemBuilder: (context, index) => _buildPersonCard(_people[index]),
    );
  }

  Widget _buildPersonCard(PersonMention person) {
    final mentionCount = _mentionCounts[person.name] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.relationship != null)
              Text(person.relationship!),
            if (person.note != null)
              Text(
                person.note!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$mentionCount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            Text(
              'mentions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouTab() {
    if (_thankYouNotes.isEmpty) {
      return _buildEmptyThankYouState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _thankYouNotes.length,
      itemBuilder: (context, index) => _buildThankYouCard(_thankYouNotes[index]),
    );
  }

  Widget _buildThankYouCard(ThankYouNote note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.red[400], size: 20),
                const SizedBox(width: 8),
                Text(
                  'To ${note.personName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(note.type.name),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.message),
            if (note.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'For: ${note.reason}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(note.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPeopleState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No people mentioned yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing about the people in your life!',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyThankYouState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No thank you notes yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Express gratitude to people who matter!',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}