import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_models.dart';

class DiaryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static const String _diaryCollection = 'diary_entries';
  static const String _promptsCollection = 'writing_prompts';

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // CRUD Operations for Diary Entries
  Future<String> createDiaryEntry(DiaryEntry entry) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      // Generate AI content
      final enhancedEntry = await _enhanceWithAI(entry);
      
      // Save to Firestore
      final docRef = await _firestore
          .collection(_diaryCollection)
          .add(enhancedEntry.toMap());

      // Update analytics
      await _updateWritingStreak();
      await _analytics.logEvent(name: 'diary_entry_created', parameters: {
        'entry_length': entry.content.length,
        'mood': entry.mood.type.name,
        'has_moments': entry.moments.isNotEmpty ? 1 : 0,  // Convert to number
        'has_thanks': entry.thankYouNotes.isNotEmpty ? 1 : 0,  // Convert to number
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create diary entry: $e');
    }
  }

  Future<void> updateDiaryEntry(String id, DiaryEntry entry) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      final enhancedEntry = await _enhanceWithAI(entry);
      
      await _firestore
          .collection(_diaryCollection)
          .doc(id)
          .update(enhancedEntry.toMap());

      await _analytics.logEvent(name: 'diary_entry_updated', parameters: {
        'entry_id': id,
      });
    } catch (e) {
      throw Exception('Failed to update diary entry: $e');
    }
  }

  Future<void> deleteDiaryEntry(String id) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore.collection(_diaryCollection).doc(id).delete();
      await _analytics.logEvent(name: 'diary_entry_deleted');
    } catch (e) {
      throw Exception('Failed to delete diary entry: $e');
    }
  }

  Future<DiaryEntry?> getDiaryEntry(String id) async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore.collection(_diaryCollection).doc(id).get();
      if (doc.exists && doc.data()!['userId'] == _currentUserId) {
        final data = doc.data()!;
        data['id'] = doc.id; // Set the document ID
        return DiaryEntry.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get diary entry: $e');
    }
  }

  // Get diary entries with pagination and filtering
  Future<List<DiaryEntry>> getDiaryEntries({
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    MoodType? mood,
    bool? isFavorite,
    DocumentSnapshot? lastDocument,
  }) async {
    if (_currentUserId == null) return [];

    try {
      // Use a simpler query that works with existing indexes
      Query query = _firestore
          .collection(_diaryCollection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      List<DiaryEntry> entries = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id; // Set the document ID
            return DiaryEntry.fromMap(data);
          })
          .toList();

      // Apply client-side filtering for now to avoid more complex indexes
      if (startDate != null) {
        entries = entries.where((entry) => entry.date.isAfter(startDate.subtract(const Duration(days: 1)))).toList();
      }
      if (endDate != null) {
        entries = entries.where((entry) => entry.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
      }
      if (mood != null) {
        entries = entries.where((entry) => entry.mood.type == mood).toList();
      }
      if (isFavorite != null) {
        entries = entries.where((entry) => entry.isFavorite == isFavorite).toList();
      }

      // Filter by tags if specified (client-side filtering)
      if (tags != null && tags.isNotEmpty) {
        entries = entries.where((entry) {
          return tags.any((tag) => entry.tags.contains(tag) || entry.aiTags.contains(tag));
        }).toList();
      }

      // Sort by date after filtering
      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get diary entries: $e');
    }
  }

  // Get entries for a specific date
  Future<DiaryEntry?> getEntryForDate(DateTime date) async {
    if (_currentUserId == null) return null;

    try {
      // Use a simpler query and filter client-side
      final snapshot = await _firestore
          .collection(_diaryCollection)
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(100)  // Get recent entries and filter client-side
          .get();

      final entries = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Set the document ID
            return DiaryEntry.fromMap(data);
          })
          .where((entry) {
            final entryDate = entry.date;
            return entryDate.year == date.year &&
                   entryDate.month == date.month &&
                   entryDate.day == date.day;
          })
          .toList();

      return entries.isNotEmpty ? entries.first : null;
    } catch (e) {
      throw Exception('Failed to get entry for date: $e');
    }
  }

  // Moments Management
  Future<List<DiaryMoment>> getAllMoments() async {
    if (_currentUserId == null) return [];

    try {
      final entries = await getDiaryEntries(limit: 1000);
      final allMoments = <DiaryMoment>[];
      
      for (final entry in entries) {
        allMoments.addAll(entry.moments);
      }
      
      // Sort by happiness score and timestamp
      allMoments.sort((a, b) {
        final happinessDiff = b.happiness.compareTo(a.happiness);
        if (happinessDiff != 0) return happinessDiff;
        return b.timestamp.compareTo(a.timestamp);
      });

      return allMoments;
    } catch (e) {
      throw Exception('Failed to get moments: $e');
    }
  }

  Future<List<DiaryMoment>> getMomentsByType(MomentType type) async {
    final allMoments = await getAllMoments();
    return allMoments.where((moment) => moment.type == type).toList();
  }

  // People Management
  Future<List<PersonMention>> getAllPeopleMentioned() async {
    if (_currentUserId == null) return [];

    try {
      final entries = await getDiaryEntries(limit: 1000);
      final peopleMap = <String, PersonMention>{};
      
      for (final entry in entries) {
        for (final person in entry.peopleMentioned) {
          peopleMap[person.name] = person;
        }
      }
      
      return peopleMap.values.toList();
    } catch (e) {
      throw Exception('Failed to get people: $e');
    }
  }

  Future<Map<String, int>> getPeopleMentionCounts() async {
    if (_currentUserId == null) return {};

    try {
      final entries = await getDiaryEntries(limit: 1000);
      final counts = <String, int>{};
      
      for (final entry in entries) {
        for (final person in entry.peopleMentioned) {
          counts[person.name] = (counts[person.name] ?? 0) + 1;
        }
      }
      
      return counts;
    } catch (e) {
      return {};
    }
  }

  // Thank You Notes Management
  Future<List<ThankYouNote>> getAllThankYouNotes() async {
    if (_currentUserId == null) return [];

    try {
      final entries = await getDiaryEntries(limit: 1000);
      final allNotes = <ThankYouNote>[];
      
      for (final entry in entries) {
        allNotes.addAll(entry.thankYouNotes);
      }
      
      allNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allNotes;
    } catch (e) {
      throw Exception('Failed to get thank you notes: $e');
    }
  }

  Future<List<ThankYouNote>> getThankYouNotesForPerson(String personName) async {
    final allNotes = await getAllThankYouNotes();
    return allNotes.where((note) => note.personName == personName).toList();
  }

  // AI Enhancement Features
  Future<DiaryEntry> _enhanceWithAI(DiaryEntry entry) async {
    try {
      // Generate sentiment score
      final sentiment = await _analyzeSentiment(entry.content);
      
      // Generate AI tags
      final aiTags = await _generateTags(entry.content);
      
      // Generate summary for long entries
      String? summary;
      if (entry.content.length > 500) {
        summary = await _generateSummary(entry.content);
      }

      return entry.copyWith(
        sentimentScore: sentiment,
        aiTags: aiTags,
        aiSummary: summary,
      );
    } catch (e) {
      // Return original entry if AI enhancement fails
      return entry;
    }
  }

  Future<double> _analyzeSentiment(String text) async {
    try {
      // Simple sentiment analysis using word counting
      // In production, you'd use a proper sentiment analysis API
      final positiveWords = ['happy', 'great', 'amazing', 'wonderful', 'excellent', 
                            'fantastic', 'awesome', 'good', 'love', 'joy', 'excited',
                            'grateful', 'thankful', 'blessed', 'peaceful', 'content'];
      final negativeWords = ['sad', 'angry', 'frustrated', 'terrible', 'awful', 
                            'bad', 'hate', 'stressed', 'worried', 'anxious', 'upset',
                            'disappointed', 'confused', 'tired', 'exhausted'];

      final words = text.toLowerCase().split(RegExp(r'\W+'));
      int positiveCount = 0;
      int negativeCount = 0;

      for (final word in words) {
        if (positiveWords.contains(word)) positiveCount++;
        if (negativeWords.contains(word)) negativeCount++;
      }

      final totalSentimentWords = positiveCount + negativeCount;
      if (totalSentimentWords == 0) return 0.0;

      return (positiveCount - negativeCount) / totalSentimentWords;
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<String>> _generateTags(String content) async {
    try {
      final tags = <String>[];
      final text = content.toLowerCase();

      // Activity tags
      if (text.contains(RegExp(r'\b(work|office|meeting|project)\b'))) tags.add('work');
      if (text.contains(RegExp(r'\b(family|mom|dad|brother|sister|parent)\b'))) tags.add('family');
      if (text.contains(RegExp(r'\b(friend|friends|buddy|pal)\b'))) tags.add('friends');
      if (text.contains(RegExp(r'\b(exercise|gym|running|walking|sport)\b'))) tags.add('fitness');
      if (text.contains(RegExp(r'\b(food|dinner|lunch|cooking|restaurant)\b'))) tags.add('food');
      if (text.contains(RegExp(r'\b(travel|trip|vacation|adventure)\b'))) tags.add('travel');
      if (text.contains(RegExp(r'\b(learning|study|book|course|education)\b'))) tags.add('learning');
      if (text.contains(RegExp(r'\b(music|movie|show|art|creative)\b'))) tags.add('entertainment');
      if (text.contains(RegExp(r'\b(nature|park|outdoor|garden|beach)\b'))) tags.add('nature');
      if (text.contains(RegExp(r'\b(love|relationship|romantic|date)\b'))) tags.add('love');

      return tags.take(5).toList(); // Limit to 5 tags
    } catch (e) {
      return [];
    }
  }

  Future<String> _generateSummary(String content) async {
    try {
      // Simple extractive summarization
      final sentences = content.split(RegExp(r'[.!?]+'));
      if (sentences.length <= 2) return content;

      // Take first and last sentence as summary
      final firstSentence = sentences.first.trim();
      final lastSentence = sentences.last.trim();
      
      if (firstSentence.isNotEmpty && lastSentence.isNotEmpty) {
        return '$firstSentence... $lastSentence';
      }
      return content.substring(0, content.length ~/ 3) + '...';
    } catch (e) {
      return content;
    }
  }

  // Writing Prompts
  Future<List<WritingPrompt>> getWritingPrompts({PromptCategory? category}) async {
    try {
      Query query = _firestore.collection(_promptsCollection);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => WritingPrompt.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return default prompts if Firestore fails
      return _getDefaultPrompts(category);
    }
  }

  List<WritingPrompt> _getDefaultPrompts(PromptCategory? category) {
    final defaultPrompts = {
      PromptCategory.reflection: [
        "What was the most meaningful moment of your day?",
        "What did you learn about yourself today?",
        "How did you grow as a person today?",
        "What challenged you today and how did you handle it?",
      ],
      PromptCategory.gratitude: [
        "What are three things you're grateful for today?",
        "Who made your day better and how?",
        "What small moment brought you joy today?",
        "What comfort or luxury did you appreciate today?",
      ],
      PromptCategory.goals: [
        "What progress did you make toward your goals today?",
        "What would you like to accomplish tomorrow?",
        "What skills did you practice or develop today?",
        "How did you invest in your future today?",
      ],
      PromptCategory.relationships: [
        "How did you connect with someone special today?",
        "What act of kindness did you witness or perform?",
        "How did you show love or appreciation today?",
        "What did you learn from someone else today?",
      ],
      PromptCategory.creativity: [
        "What inspired you today?",
        "How did you express your creativity?",
        "What new idea came to you today?",
        "What beauty did you notice today?",
      ],
      PromptCategory.mindfulness: [
        "How are you feeling right now, and why?",
        "What did you notice about your surroundings today?",
        "When did you feel most present today?",
        "What emotions did you experience today?",
      ],
      PromptCategory.general: [
        "Describe your day in three words, then elaborate.",
        "What was different about today compared to yesterday?",
        "If today were a movie, what would it be called?",
        "What advice would you give your past self from this morning?",
      ],
    };

    final prompts = category != null 
        ? defaultPrompts[category] ?? []
        : defaultPrompts.values.expand((list) => list).toList();

    return prompts.asMap().entries.map((entry) => WritingPrompt(
      id: 'default_${entry.key}',
      prompt: entry.value,
      category: category ?? PromptCategory.general,
    )).toList();
  }

  Future<WritingPrompt> getRandomPrompt() async {
    final prompts = await getWritingPrompts();
    if (prompts.isEmpty) return _getDefaultPrompts(null).first;
    
    prompts.shuffle();
    return prompts.first;
  }

  // Analytics and Insights
  Future<DiaryAnalytics> generateAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    try {
      final entries = await getDiaryEntries(
        startDate: start,
        endDate: end,
        limit: 1000,
      );

      // Calculate statistics
      final totalWords = entries.fold<int>(
        0,
        (sum, entry) => sum + entry.content.split(RegExp(r'\s+')).length,
      );

      final moodCounts = <MoodType, int>{};
      final tagCounts = <String, int>{};
      final peopleCounts = <String, int>{};
      var totalMoments = 0;
      var totalThankYous = 0;
      var totalSentiment = 0.0;

      for (final entry in entries) {
        // Mood distribution
        moodCounts[entry.mood.type] = (moodCounts[entry.mood.type] ?? 0) + 1;
        
        // Tag counts
        for (final tag in entry.tags + entry.aiTags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
        
        // People counts
        for (final person in entry.peopleMentioned) {
          peopleCounts[person.name] = (peopleCounts[person.name] ?? 0) + 1;
        }
        
        totalMoments += entry.moments.length;
        totalThankYous += entry.thankYouNotes.length;
        totalSentiment += entry.sentimentScore;
      }

      // Calculate streaks
      final streak = await _calculateWritingStreak();

      // Get top items
      final topTags = Map.fromEntries(
        tagCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10)
      );

      final topPeople = Map.fromEntries(
        peopleCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(10)
      );

      // Get top memories (highest happiness moments)
      final allMoments = entries.expand((e) => e.moments).toList();
      allMoments.sort((a, b) => b.happiness.compareTo(a.happiness));
      final topMemories = allMoments.take(5).map((m) => m.title).toList();

      return DiaryAnalytics(
        userId: _currentUserId!,
        startDate: start,
        endDate: end,
        totalEntries: entries.length,
        totalWords: totalWords,
        totalMoments: totalMoments,
        totalThankYouNotes: totalThankYous,
        moodDistribution: moodCounts,
        topTags: topTags,
        topPeople: topPeople,
        averageSentiment: entries.isNotEmpty ? totalSentiment / entries.length : 0.0,
        writingStreak: streak,
        longestStreak: await _getLongestStreak(),
        topMemories: topMemories,
      );
    } catch (e) {
      throw Exception('Failed to generate analytics: $e');
    }
  }

  // Streak Management
  Future<void> _updateWritingStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    await prefs.setString('last_write_date', todayKey);
  }

  Future<int> _calculateWritingStreak() async {
    final entries = await getDiaryEntries(limit: 365); // Get last year
    
    if (entries.isEmpty) return 0;

    int streak = 0;
    var currentDate = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final hasEntry = entries.any((entry) {
        final entryDate = entry.date;
        return entryDate.year == currentDate.year &&
               entryDate.month == currentDate.month &&
               entryDate.day == currentDate.day;
      });
      
      if (hasEntry) {
        streak++;
      } else {
        break;
      }
      
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  Future<int> _getLongestStreak() async {
    final entries = await getDiaryEntries(limit: 1000);
    if (entries.isEmpty) return 0;

    // Group entries by date
    final dateSet = <String>{};
    for (final entry in entries) {
      final dateKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      dateSet.add(dateKey);
    }

    // Calculate longest streak
    int maxStreak = 0;
    int currentStreak = 0;
    var currentDate = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final dateKey = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
      
      if (dateSet.contains(dateKey)) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else {
        currentStreak = 0;
      }
      
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return maxStreak;
  }

  // Search functionality
  Future<List<DiaryEntry>> searchEntries(String query) async {
    if (_currentUserId == null || query.isEmpty) return [];

    try {
      final allEntries = await getDiaryEntries(limit: 1000);
      final searchQuery = query.toLowerCase();

      return allEntries.where((entry) {
        return entry.title.toLowerCase().contains(searchQuery) ||
               entry.content.toLowerCase().contains(searchQuery) ||
               entry.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
               entry.aiTags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
               entry.peopleMentioned.any((person) => 
                 person.name.toLowerCase().contains(searchQuery)) ||
               entry.thankYouNotes.any((note) => 
                 note.message.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Export functionality
  Future<String> exportDiary({DateTime? startDate, DateTime? endDate}) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    try {
      final entries = await getDiaryEntries(
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );

      final buffer = StringBuffer();
      buffer.writeln('# My Diary Export');
      buffer.writeln('Generated on: ${DateTime.now()}');
      buffer.writeln('Total entries: ${entries.length}');
      buffer.writeln('');

      for (final entry in entries) {
        buffer.writeln('## ${entry.title}');
        buffer.writeln('**Date:** ${entry.date}');
        buffer.writeln('**Mood:** ${entry.mood.type.name} (${entry.mood.intensity}/10)');
        if (entry.tags.isNotEmpty) {
          buffer.writeln('**Tags:** ${entry.tags.join(', ')}');
        }
        buffer.writeln('');
        buffer.writeln(entry.content);
        
        if (entry.moments.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('**Best Moments:**');
          for (final moment in entry.moments) {
            buffer.writeln('- ${moment.title}: ${moment.description}');
          }
        }
        
        if (entry.thankYouNotes.isNotEmpty) {
          buffer.writeln('');
          buffer.writeln('**Thank You Notes:**');
          for (final note in entry.thankYouNotes) {
            buffer.writeln('- To ${note.personName}: ${note.message}');
          }
        }
        
        buffer.writeln('');
        buffer.writeln('---');
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      throw Exception('Export failed: $e');
    }
  }
}