import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/diary_models.dart';
import '../services/diary_service.dart';

class DiaryAnalyticsScreen extends StatefulWidget {
  final DiaryService diaryService;

  const DiaryAnalyticsScreen({
    super.key,
    required this.diaryService,
  });

  @override
  State<DiaryAnalyticsScreen> createState() => _DiaryAnalyticsScreenState();
}

class _DiaryAnalyticsScreenState extends State<DiaryAnalyticsScreen> {
  DiaryAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final analytics = await widget.diaryService.generateAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary Analytics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No data available'))
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildMoodChart(),
          const SizedBox(height: 24),
          _buildTopTags(),
          const SizedBox(height: 24),
          _buildTopPeople(),
          const SizedBox(height: 24),
          _buildTopMemories(),
          const SizedBox(height: 100), // Add extra bottom padding to prevent overflow
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return SizedBox(
      height: 220, // Increased height to prevent overflow
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6, // Adjusted for better proportions
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildStatCard(
            'Total Entries',
            _analytics!.totalEntries.toString(),
            Icons.book,
            Colors.blue,
          ),
          _buildStatCard(
            'Writing Streak',
            '${_analytics!.writingStreak} days',
            Icons.local_fire_department,
            Colors.orange,
          ),
          _buildStatCard(
            'Total Words',
            _analytics!.totalWords.toString(),
            Icons.text_fields,
            Colors.green,
          ),
          _buildStatCard(
            'Best Moments',
            _analytics!.totalMoments.toString(),
            Icons.star,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // Slightly smaller icon
            const SizedBox(height: 6), // Reduced spacing
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4), // Reduced spacing
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11, // Slightly smaller
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mood Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final colors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green,
      Colors.blue, Colors.indigo, Colors.purple, Colors.pink,
    ];
    
    int colorIndex = 0;
    return _analytics!.moodDistribution.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.value}',
        color: color,
        radius: 60,
      );
    }).toList();
  }

  Widget _buildTopTags() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_analytics!.topTags.isEmpty)
              const Text('No tags yet')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _analytics!.topTags.entries.take(10).map((entry) => 
                  Chip(
                    label: Text('${entry.key} (${entry.value})'),
                    backgroundColor: Colors.blue[100],
                  ),
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPeople() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Mentioned People',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_analytics!.topPeople.isEmpty)
              const Text('No people mentioned yet')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300), // Prevent overflow
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _analytics!.topPeople.entries.take(5).map((entry) => 
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                      title: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${entry.value} mentions',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMemories() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Memories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_analytics!.topMemories.isEmpty)
              const Text('No memories yet')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250), // Prevent overflow
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _analytics!.topMemories.map((memory) => 
                    ListTile(
                      leading: Icon(Icons.star, color: Colors.amber[600]),
                      title: Text(
                        memory,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}