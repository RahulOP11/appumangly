import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diary_models.dart';
import '../services/diary_service.dart';
import '../widgets/photo_upload_widget.dart';

class DiaryEntryComposerScreen extends StatefulWidget {
  final DiaryEntry? entry; // null for new entry, existing entry for editing
  final String? prompt; // optional writing prompt
  final DateTime? selectedDate; // optional date for new entry
  final Function(DiaryEntry) onSaved;

  const DiaryEntryComposerScreen({
    super.key,
    this.entry,
    this.prompt,
    this.selectedDate,
    required this.onSaved,
  });

  @override
  State<DiaryEntryComposerScreen> createState() => _DiaryEntryComposerScreenState();
}

class _DiaryEntryComposerScreenState extends State<DiaryEntryComposerScreen>
    with TickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late AnimationController _saveButtonController;
  
  MoodType _selectedMood = MoodType.neutral;
  int _moodIntensity = 5;
  String _moodNote = '';
  List<String> _selectedEmotions = [];
  List<String> _tags = [];
  List<DiaryMoment> _moments = [];
  List<PersonMention> _peopleMentioned = [];
  List<ThankYouNote> _thankYouNotes = [];
  List<String> _photoUrls = [];
  bool _isFavorite = false;
  bool _isSaving = false;

  final List<String> _availableEmotions = [
    'happy', 'excited', 'grateful', 'proud', 'content', 'peaceful',
    'sad', 'frustrated', 'worried', 'angry', 'confused', 'disappointed',
    'hopeful', 'inspired', 'relaxed', 'energetic', 'nostalgic', 'curious'
  ];

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize with existing entry data if editing
    if (widget.entry != null) {
      _initializeWithEntry(widget.entry!);
    } else if (widget.prompt != null) {
      _initializeWithPrompt(widget.prompt!);
    }
  }

  void _initializeWithEntry(DiaryEntry entry) {
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _selectedMood = entry.mood.type;
    _moodIntensity = entry.mood.intensity;
    _moodNote = entry.mood.note ?? '';
    _selectedEmotions = List.from(entry.mood.emotions);
    _tags = List.from(entry.tags);
    _moments = List.from(entry.moments);
    _peopleMentioned = List.from(entry.peopleMentioned);
    _thankYouNotes = List.from(entry.thankYouNotes);
    _photoUrls = List.from(entry.photoUrls);
    _isFavorite = entry.isFavorite;
  }

  void _initializeWithPrompt(String prompt) {
    _contentController.text = '$prompt\n\n';
    _titleController.text = 'Prompted Entry';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => _showExitConfirmation(),
          icon: const Icon(Icons.close, color: Colors.black54),
        ),
        title: Text(
          widget.entry == null ? 'New Entry' : 'Edit Entry',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey[600],
            ),
          ),
          AnimatedBuilder(
            animation: _saveButtonController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_saveButtonController.value * 0.1),
                child: TextButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  child: _isSaving 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildContentField(),
            const SizedBox(height: 24),
            _buildMoodSection(),
            const SizedBox(height: 24),
            _buildEmotionsSection(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 24),
            _buildMomentsSection(),
            const SizedBox(height: 24),
            _buildPeopleSection(),
            const SizedBox(height: 24),
            _buildThankYouSection(),
            const SizedBox(height: 24),
            _buildPhotosSection(),
            const SizedBox(height: 100), // Space for floating action button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveEntry,
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        icon: _isSaving 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
      ),
    );
  }

  Widget _buildTitleField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.title, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Give your entry a title...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Story',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_contentController.text.length} characters',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 8,
              decoration: const InputDecoration(
                hintText: 'What happened today? How are you feeling? What are you thinking about?',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 16, height: 1.5),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'How are you feeling?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: MoodType.values.map((mood) {
                final isSelected = mood == _selectedMood;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? Colors.orange[100]
                        : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                          ? Colors.orange[400]! 
                          : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getMoodEmoji(mood), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          mood.name,
                          style: TextStyle(
                            color: isSelected ? Colors.orange[700] : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Intensity (1-10)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _moodIntensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _moodIntensity.toString(),
              activeColor: Colors.orange[600],
              onChanged: (value) {
                setState(() => _moodIntensity = value.round());
              },
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => _moodNote = value,
              decoration: const InputDecoration(
                hintText: 'Add a note about your mood (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Emotions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedEmotions.length} selected',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableEmotions.map((emotion) {
                final isSelected = _selectedEmotions.contains(emotion);
                return FilterChip(
                  label: Text(emotion),
                  selected: isSelected,
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[700],
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEmotions.add(emotion);
                      } else {
                        _selectedEmotions.remove(emotion);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_tags.isEmpty)
              Text(
                'Add tags to categorize this entry',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.green[100],
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Best Moments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addMoment,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_moments.isEmpty)
              Text(
                'Capture the special moments from today',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Column(
                children: _moments.map((moment) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber[100],
                      child: Icon(Icons.star, color: Colors.amber[700], size: 16),
                    ),
                    title: Text(moment.title),
                    subtitle: Text(moment.description, maxLines: 2),
                    trailing: IconButton(
                      onPressed: () => setState(() => _moments.remove(moment)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.indigo[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'People I Met',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addPerson,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_peopleMentioned.isEmpty)
              Text(
                'Who did you spend time with today?',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Column(
                children: _peopleMentioned.map((person) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[100],
                      child: Text(
                        person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(person.name),
                    subtitle: Text(person.relationship ?? 'No relationship specified'),
                    trailing: IconButton(
                      onPressed: () => setState(() => _peopleMentioned.remove(person)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThankYouSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Thank You Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addThankYouNote,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_thankYouNotes.isEmpty)
              Text(
                'Express gratitude to someone special',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Column(
                children: _thankYouNotes.map((note) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink[100],
                      child: Icon(Icons.favorite, color: Colors.pink[700], size: 16),
                    ),
                    title: Text('To ${note.personName}'),
                    subtitle: Text(note.message, maxLines: 2),
                    trailing: IconButton(
                      onPressed: () => setState(() => _thankYouNotes.remove(note)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PhotoUploadWidget(
          initialPhotos: _photoUrls,
          onPhotosChanged: (photos) {
            setState(() {
              _photoUrls = photos;
            });
          },
          maxPhotos: 5,
        ),
      ),
    );
  }

  String _getMoodEmoji(MoodType mood) {
    switch (mood) {
      case MoodType.ecstatic: return '🤩';
      case MoodType.happy: return '😊';
      case MoodType.content: return '😌';
      case MoodType.neutral: return '😐';
      case MoodType.sad: return '😢';
      case MoodType.angry: return '😠';
      case MoodType.anxious: return '😰';
      case MoodType.excited: return '🤗';
      case MoodType.grateful: return '🙏';
      case MoodType.peaceful: return '🧘';
      case MoodType.confused: return '🤔';
      case MoodType.inspired: return '✨';
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) {
        String newTag = '';
        return AlertDialog(
          title: const Text('Add Tag'),
          content: TextField(
            onChanged: (value) => newTag = value,
            decoration: const InputDecoration(
              hintText: 'Enter tag name',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                  setState(() => _tags.add(newTag));
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addMoment() {
    showDialog(
      context: context,
      builder: (context) => _MomentDialog(
        onSaved: (moment) {
          setState(() => _moments.add(moment));
        },
      ),
    );
  }

  void _addPerson() {
    showDialog(
      context: context,
      builder: (context) => _PersonDialog(
        onSaved: (person) {
          setState(() => _peopleMentioned.add(person));
        },
      ),
    );
  }

  void _addThankYouNote() {
    showDialog(
      context: context,
      builder: (context) => _ThankYouDialog(
        onSaved: (note) {
          setState(() => _thankYouNotes.add(note));
        },
      ),
    );
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title or content')),
      );
      return;
    }

    setState(() => _isSaving = true);
    _saveButtonController.forward();

    try {
      final now = DateTime.now();
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final mood = DiaryMood(
        type: _selectedMood,
        intensity: _moodIntensity,
        note: _moodNote.isNotEmpty ? _moodNote : null,
        emotions: _selectedEmotions,
      );

      final entry = DiaryEntry(
        id: widget.entry?.id ?? '',
        userId: currentUser.uid,
        date: widget.entry?.date ?? widget.selectedDate ?? now,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        mood: mood,
        moments: _moments,
        peopleMentioned: _peopleMentioned,
        thankYouNotes: _thankYouNotes,
        photoUrls: _photoUrls,
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
        isFavorite: _isFavorite,
      );

      if (widget.entry == null) {
        await _diaryService.createDiaryEntry(entry);
      } else {
        await _diaryService.updateDiaryEntry(widget.entry!.id, entry);
      }

      widget.onSaved(entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        _saveButtonController.reverse();
      }
    }
  }

  void _showExitConfirmation() {
    final hasChanges = _titleController.text.isNotEmpty ||
                      _contentController.text.isNotEmpty ||
                      _tags.isNotEmpty ||
                      _moments.isNotEmpty ||
                      _peopleMentioned.isNotEmpty ||
                      _thankYouNotes.isNotEmpty;

    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close editor
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

// Helper dialogs for adding complex data
class _MomentDialog extends StatefulWidget {
  final Function(DiaryMoment) onSaved;

  const _MomentDialog({required this.onSaved});

  @override
  State<_MomentDialog> createState() => _MomentDialogState();
}

class _MomentDialogState extends State<_MomentDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  MomentType _type = MomentType.other;
  int _happiness = 10;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Best Moment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Moment title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MomentType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: MomentType.values.map((type) => 
                DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                ),
              ).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            Text('Happiness: $_happiness/10'),
            Slider(
              value: _happiness.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _happiness = value.round()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final moment = DiaryMoment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                description: _descriptionController.text,
                timestamp: DateTime.now(),
                type: _type,
                happiness: _happiness,
              );
              widget.onSaved(moment);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _PersonDialog extends StatefulWidget {
  final Function(PersonMention) onSaved;

  const _PersonDialog({required this.onSaved});

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Person'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(labelText: 'Relationship (optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              final person = PersonMention(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                relationship: _relationshipController.text.isNotEmpty 
                  ? _relationshipController.text 
                  : null,
                note: _noteController.text.isNotEmpty 
                  ? _noteController.text 
                  : null,
              );
              widget.onSaved(person);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ThankYouDialog extends StatefulWidget {
  final Function(ThankYouNote) onSaved;

  const _ThankYouDialog({required this.onSaved});

  @override
  State<_ThankYouDialog> createState() => _ThankYouDialogState();
}

class _ThankYouDialogState extends State<_ThankYouDialog> {
  final _personController = TextEditingController();
  final _messageController = TextEditingController();
  final _reasonController = TextEditingController();
  ThankYouType _type = ThankYouType.general;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Thank You Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _personController,
              decoration: const InputDecoration(labelText: 'Person\'s name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Thank you message'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason/What for'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ThankYouType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ThankYouType.values.map((type) => 
                DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                ),
              ).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_personController.text.isNotEmpty && _messageController.text.isNotEmpty) {
              final note = ThankYouNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                personName: _personController.text,
                message: _messageController.text,
                reason: _reasonController.text,
                type: _type,
                createdAt: DateTime.now(),
              );
              widget.onSaved(note);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}