import 'package:flutter/material.dart';
import '../models/smile_models.dart';
import '../services/smile_rewards_service.dart';
import 'simplified_smile_boost_screen.dart';

class SmileBoostScreen extends StatefulWidget {
  const SmileBoostScreen({super.key});

  @override
  State<SmileBoostScreen> createState() => _SmileBoostScreenState();
}

class _SmileBoostScreenState extends State<SmileBoostScreen> {
  UserSmileStats _userStats = UserSmileStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await SmileRewardsService.getUserStats();
      setState(() {
        _userStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading 
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    // Header
                    _buildHeader(),
                    
                    // Stats Cards
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStatsGrid(),
                            const SizedBox(height: 20),
                            _buildProgressCard(),
                            const SizedBox(height: 20),
                            _buildTodayActivityCard(),
                            const SizedBox(height: 20),
                            _buildStartSmileButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Smile Boost Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _loadUserStats,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Points',
          '${_userStats.totalPoints}',
          '🏆',
          Colors.amber,
        ),
        _buildStatCard(
          'Today\'s Smiles',
          '${_userStats.dailySmiles}',
          '😊',
          Colors.pink,
        ),
        _buildStatCard(
          'Streak Days',
          '${_userStats.streakDays}',
          '🔥',
          Colors.orange,
        ),
        _buildStatCard(
          'Total Smiles',
          '${_userStats.totalSmiles}',
          '🌟',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    int dailyGoal = 10;
    double progress = _userStats.dailySmiles / dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '🎯',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 10),
              Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_userStats.dailySmiles} / $dailyGoal smiles',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 10),
          Text(
            _userStats.dailySmiles >= dailyGoal
                ? '🎉 Daily goal achieved! Amazing work!'
                : 'Keep going! ${dailyGoal - _userStats.dailySmiles} more smiles to reach your daily goal.',
            style: TextStyle(
              fontSize: 12,
              color: _userStats.dailySmiles >= dailyGoal ? Colors.green : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '📊',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(width: 10),
              Text(
                'Today\'s Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_userStats.todaySmiles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '😴',
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No smiles recorded today',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Start your first smile session!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Points Earned: ${_userStats.todaySmiles.fold(0, (sum, smile) => sum + smile.pointsEarned)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _userStats.todaySmiles.length,
                    itemBuilder: (context, index) {
                      final smile = _userStats.todaySmiles[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              smile.isSmiling ? '😊' : '😐',
                              style: const TextStyle(fontSize: 20),
                            ),
                            Text(
                              '+${smile.pointsEarned}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStartSmileButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SimplifiedSmileBoostScreen(),
            ),
          );
          
          if (result == true) {
            _loadUserStats(); // Refresh stats after smile session
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF667eea),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_emotions,
              size: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Start Smile Session',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '�',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}