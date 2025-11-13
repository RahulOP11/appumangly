import 'package:flutter/material.dart';
import '../models/diary_models.dart';
import '../services/diary_service.dart';

class DiaryMomentsScreen extends StatefulWidget {
  final DiaryService diaryService;

  const DiaryMomentsScreen({
    super.key,
    required this.diaryService,
  });

  @override
  State<DiaryMomentsScreen> createState() => _DiaryMomentsScreenState();
}

class _DiaryMomentsScreenState extends State<DiaryMomentsScreen> {
  List<DiaryMoment> _moments = [];
  bool _isLoading = true;
  MomentType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    setState(() => _isLoading = true);
    try {
      final moments = await widget.diaryService.getAllMoments();
      setState(() {
        _moments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading moments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMoments = _filterType == null
        ? _moments
        : _moments.where((m) => m.type == _filterType).toList();

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredMoments.isEmpty
                  ? _buildEmptyState()
                  : _buildMomentsList(filteredMoments),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filterType == null,
              onSelected: (selected) {
                setState(() => _filterType = selected ? null : _filterType);
              },
            ),
            const SizedBox(width: 8),
            ...MomentType.values.map((type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.name),
                selected: _filterType == type,
                onSelected: (selected) {
                  setState(() => _filterType = selected ? type : null);
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentsList(List<DiaryMoment> moments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: moments.length,
      itemBuilder: (context, index) => _buildMomentCard(moments[index]),
    );
  }

  Widget _buildMomentCard(DiaryMoment moment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    moment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${moment.happiness}/10',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(moment.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(moment.type.name),
                  backgroundColor: Colors.blue[100],
                ),
                const Spacer(),
                Text(
                  _formatDate(moment.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No moments yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing your best moments!',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}