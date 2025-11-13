import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:io';
import '../models/diary_models.dart';
import '../services/diary_service.dart';
import 'diary_entry_composer_screen.dart';
import 'diary_entry_view_screen.dart';
import 'diary_moments_screen.dart';
import 'diary_people_screen.dart';
import 'diary_analytics_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> 
    with TickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  
  late TabController _tabController;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  DiaryEntry? _todayEntry;
  DateTime _selectedDate = DateTime.now();
  List<DiaryEntry> _entriesForSelectedDate = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    
    _loadDiaryData();
    _fabController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaryData() async {
    setState(() => _isLoading = true);
    
    try {
      final entries = await _diaryService.getDiaryEntries(limit: 50);
      final todayEntry = await _diaryService.getEntryForDate(DateTime.now());
      
      setState(() {
        _entries = entries;
        _todayEntry = todayEntry;
        _entriesForSelectedDate = _getEntriesForDay(_selectedDate);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _entries = [];  // Fallback to empty list
        _todayEntry = null;
        _entriesForSelectedDate = [];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading diary: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Diary',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(),
            icon: const Icon(Icons.search, color: Colors.black54),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Diary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.purple[600],
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Today'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.list), text: 'Entries'),
            Tab(icon: Icon(Icons.photo_album), text: 'Moments'),
            Tab(icon: Icon(Icons.people), text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildCalendarTab(),
          _buildEntriesTab(),
          _buildMomentsTab(),
          _buildPeopleTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: _createNewEntry,
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit),
              label: const Text('Write'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadDiaryData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),
                  _buildTodayEntry(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildWritingPrompt(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? 'morning' : 
                     now.hour < 17 ? 'afternoon' : 'evening';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple[200]!.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good $timeOfDay!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getMotivationalMessage(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.today_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(now),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showDatePicker,
                icon: const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
                label: const Text(
                  'Pick Date',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayEntry() {
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
                Icon(Icons.edit_note, color: Colors.purple[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Entry',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_todayEntry != null)
                  TextButton(
                    onPressed: () => _editEntry(_todayEntry!),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todayEntry == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No entry for today yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _createNewEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Start Writing'),
                    ),
                  ],
                ),
              )
            else
              _buildEntryPreview(_todayEntry!),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryPreview(DiaryEntry entry) {
    return GestureDetector(
      onTap: () => _viewEntry(entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title.isNotEmpty ? entry.title : 'Untitled',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            entry.content,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Photos preview
          if (entry.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: entry.photoUrls.take(3).length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildImageWidget(entry.photoUrls[index]),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // Quick info for moments and people
          if (entry.moments.isNotEmpty || entry.peopleMentioned.isNotEmpty || entry.thankYouNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (entry.moments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.orange[700]),
                        const SizedBox(width: 2),
                        Text(
                          '${entry.moments.length} moment${entry.moments.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.peopleMentioned.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 2),
                        Text(
                          '${entry.peopleMentioned.length} people',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (entry.thankYouNotes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, size: 12, color: Colors.green[700]),
                        const SizedBox(width: 2),
                        Text(
                          '${entry.thankYouNotes.length} thanks',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMoodChip(entry.mood),
              const Spacer(),
              if (entry.photoUrls.isNotEmpty)
                Icon(Icons.photo_library, size: 16, color: Colors.grey[500]),
              if (entry.isFavorite) ...[
                const SizedBox(width: 4),
                Icon(Icons.favorite, size: 16, color: Colors.red[500]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.favorite_outline,
                    label: 'Best Moment',
                    color: Colors.pink,
                    onTap: () => _addBestMoment(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.people_outline,
                    label: 'Thank Someone',
                    color: Colors.green,
                    onTap: () => _addThankYouNote(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingPrompt() {
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
                Icon(Icons.lightbulb_outline, color: Colors.amber[600], size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Writing Prompt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _getNewPrompt,
                  child: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<WritingPrompt>(
              future: _diaryService.getRandomPrompt(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('Unable to load prompt');
                }
                
                final prompt = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.prompt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _createEntryWithPrompt(prompt.prompt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Start Writing'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return RefreshIndicator(
      onRefresh: _loadDiaryData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.deepPurple[600], size: 24),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TableCalendar<DiaryEntry>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _selectedDate,
                      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                      eventLoader: _getEntriesForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        selectedDecoration: BoxDecoration(
                          color: Colors.deepPurple[600],
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.deepPurple[300],
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 3,
                        markerDecoration: BoxDecoration(
                          color: Colors.orange[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple[600],
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.deepPurple[600]),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.deepPurple[600]),
                      ),
                      onDaySelected: _onDaySelected,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildEntriesForSelectedDate(),
          ],
        ),
      ),
    );
  }

  List<DiaryEntry> _getEntriesForDay(DateTime day) {
    try {
      return _entries.where((entry) {
        try {
          return isSameDay(entry.date, day);
        } catch (e) {
          return false;
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    try {
      if (!isSameDay(_selectedDate, selectedDay)) {
        setState(() {
          _selectedDate = selectedDay;
          _entriesForSelectedDate = _getEntriesForDay(selectedDay);
        });
      }
    } catch (e) {
      // Fallback if date selection fails
      print('Error selecting date: $e');
    }
  }

  Widget _buildEntriesForSelectedDate() {
    if (_entriesForSelectedDate.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_calendar, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No entries for ${_getFormattedDate(_selectedDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to create an entry for this date',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _createEntryForDate(_selectedDate),
                icon: const Icon(Icons.add),
                label: const Text('Create Entry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.event_note, color: Colors.deepPurple[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Entries for ${_getFormattedDate(_selectedDate)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[600],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _createEntryForDate(_selectedDate),
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add entry',
              ),
            ],
          ),
        ),
        ...(_entriesForSelectedDate.map((entry) {
          try {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildEntryCard(entry),
            );
          } catch (e) {
            // Return a safe fallback if entry rendering fails
            return Card(
              child: ListTile(
                leading: Icon(Icons.error, color: Colors.red[400]),
                title: const Text('Unable to display entry'),
                subtitle: const Text('Entry data may be corrupted'),
              ),
            );
          }
        }).toList()),
      ],
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Today';
    } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    } else if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  void _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select date for diary entry',
      cancelText: 'Cancel',
      confirmText: 'Go to Date',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.deepPurple[600],
            colorScheme: ColorScheme.light(
              primary: Colors.deepPurple[600]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _entriesForSelectedDate = _getEntriesForDay(pickedDate);
      });
      
      // Switch to calendar tab to show the selected date
      _tabController.animateTo(1);
    }
  }

  void _createEntryForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryComposerScreen(
          selectedDate: date,
          onSaved: (entry) {
            _loadDiaryData();
          },
        ),
      ),
    );
  }

  Widget _buildEntriesTab() {
    return RefreshIndicator(
      onRefresh: _loadDiaryData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryCard(_entries[index]);
                  },
                ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewEntry(entry),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (entry.title.isNotEmpty) ? entry.title : 'Untitled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(entry.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Entry content
              Text(
                entry.content,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Photos section
              if (entry.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.photoUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImageWidget(entry.photoUrls[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Best Moments section
              if (entry.moments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Best Moments',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...entry.moments.take(2).map((moment) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• ${moment.title}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[800],
                          ),
                        ),
                      )),
                      if (entry.moments.length > 2)
                        Text(
                          '...and ${entry.moments.length - 2} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              // People Mentioned section
              if (entry.peopleMentioned.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: entry.peopleMentioned.take(3).map((person) => Chip(
                    label: Text(
                      person.name,
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.person, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.blue[100],
                    labelStyle: TextStyle(color: Colors.blue[700]),
                  )).toList(),
                ),
              ],
              
              // Thank You Notes section
              if (entry.thankYouNotes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Grateful for: ${entry.thankYouNotes.first.personName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      if (entry.thankYouNotes.length > 1)
                        Text(
                          '+${entry.thankYouNotes.length - 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Tags and mood section
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMoodChip(entry.mood),
                  ...(entry.tags).take(2).map((tag) => _buildTag(tag)),
                  if (entry.aiTags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 12, color: Colors.purple[700]),
                          const SizedBox(width: 4),
                          Text(
                            entry.aiTags.first,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (entry.isFavorite)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite, size: 14, color: Colors.red[700]),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Weather and location info
              if (entry.weather != null || entry.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (entry.weather != null) ...[
                      Icon(Icons.wb_sunny, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.weather!.temperature}°C',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (entry.location != null) ...[
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.location!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMomentsTab() {
    return DiaryMomentsScreen(diaryService: _diaryService);
  }

  Widget _buildPeopleTab() {
    return DiaryPeopleScreen(diaryService: _diaryService);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your diary is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start writing your first entry to capture\nyour thoughts and memories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Start Writing'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(DiaryMood mood) {
    try {
      final colors = _getMoodColors(mood.type);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors['background'],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getMoodEmoji(mood.type),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              mood.type.name,
              style: TextStyle(
                fontSize: 12,
                color: colors['text'],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback if mood data is invalid
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Mood',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Map<String, Color> _getMoodColors(MoodType mood) {
    switch (mood) {
      case MoodType.ecstatic:
        return {'background': Colors.pink[100]!, 'text': Colors.pink[700]!};
      case MoodType.happy:
        return {'background': Colors.yellow[100]!, 'text': Colors.yellow[700]!};
      case MoodType.content:
        return {'background': Colors.green[100]!, 'text': Colors.green[700]!};
      case MoodType.neutral:
        return {'background': Colors.grey[100]!, 'text': Colors.grey[700]!};
      case MoodType.sad:
        return {'background': Colors.blue[100]!, 'text': Colors.blue[700]!};
      case MoodType.angry:
        return {'background': Colors.red[100]!, 'text': Colors.red[700]!};
      case MoodType.anxious:
        return {'background': Colors.orange[100]!, 'text': Colors.orange[700]!};
      case MoodType.excited:
        return {'background': Colors.purple[100]!, 'text': Colors.purple[700]!};
      case MoodType.grateful:
        return {'background': Colors.teal[100]!, 'text': Colors.teal[700]!};
      case MoodType.peaceful:
        return {'background': Colors.indigo[100]!, 'text': Colors.indigo[700]!};
      case MoodType.confused:
        return {'background': Colors.brown[100]!, 'text': Colors.brown[700]!};
      case MoodType.inspired:
        return {'background': Colors.amber[100]!, 'text': Colors.amber[700]!};
    }
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

  String _getMotivationalMessage() {
    final messages = [
      "Take a moment to capture today's story",
      "Your thoughts matter - let's write them down",
      "Every day has something worth remembering",
      "What made today special?",
      "Document your journey, one entry at a time",
      "Your future self will thank you for writing",
    ];
    return messages[DateTime.now().day % messages.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  void _createNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryComposerScreen(
          onSaved: (entry) {
            _loadDiaryData();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _createEntryWithPrompt(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryComposerScreen(
          prompt: prompt,
          onSaved: (entry) {
            _loadDiaryData();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _editEntry(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryComposerScreen(
          entry: entry,
          onSaved: (updatedEntry) {
            _loadDiaryData();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _viewEntry(DiaryEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryEntryViewScreen(
          entry: entry,
          onEdit: () => _editEntry(entry),
          onDeleted: () async {
            try {
              await _diaryService.deleteDiaryEntry(entry.id);
              Navigator.pop(context);
              _loadDiaryData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete entry: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _addBestMoment() {
    // TODO: Implement quick add best moment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Best moment feature coming soon!')),
    );
  }

  void _addThankYouNote() {
    // TODO: Implement quick add thank you note
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you note feature coming soon!')),
    );
  }

  void _getNewPrompt() {
    setState(() {});
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Diary'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search entries, people, tags...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryAnalyticsScreen(diaryService: _diaryService),
          ),
        );
        break;
      case 'export':
        _exportDiary();
        break;
      case 'settings':
        // TODO: Navigate to settings
        break;
    }
  }

  void _exportDiary() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting diary...'),
            ],
          ),
        ),
      );

      final exported = await _diaryService.exportDiary();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show export results
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported diary data (${exported.length} characters)'),
                const SizedBox(height: 8),
                const Text('Export data is ready to be saved or shared.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Widget _buildImageWidget(String photoUrl) {
    // Check if it's a local file path or a URL
    if (photoUrl.startsWith('http')) {
      // Network image
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    } else {
      // Local file - convert to proper display
      try {
        return Image.file(
          File(photoUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo, color: Colors.grey[600]),
                  const SizedBox(height: 4),
                  Text(
                    'Image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } catch (e) {
        // Fallback for any file access issues
        return Container(
          color: Colors.grey[300],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                'Photo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}