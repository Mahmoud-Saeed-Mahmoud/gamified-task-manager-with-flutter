import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_progress.dart';
import 'package:confetti/confetti.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final progress = taskProvider.userProgress;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Your Progress'),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLevelCard(progress),
                  const SizedBox(height: 16),
                  _buildStreakCard(progress),
                  const SizedBox(height: 16),
                  _buildBadgesCard(progress),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -3.14 / 2,
                  maxBlastForce: 100,
                  minBlastForce: 50,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(UserProgress progress) {
    final expPercentage =
        progress.experience / progress.experienceToNextLevel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level ${progress.level}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: expPercentage,
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.experience} / ${progress.experienceToNextLevel} XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(UserProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '${progress.streak} Day Streak',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Keep it up! Complete tasks daily to maintain your streak.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesCard(UserProgress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Badges',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (progress.badges.isEmpty)
              const Text('Complete tasks to earn badges!')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: progress.badges.map((badge) {
                  return Tooltip(
                    message: badge,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        _getBadgeIcon(badge),
                        color: Colors.blue[900],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge) {
      case 'Task Master':
        return Icons.star;
      case 'Week Warrior':
        return Icons.calendar_today;
      case 'Level Pro':
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }
}
