import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/user_progress.dart';

class GamificationService {
  static const String _keyPrefix = 'gamification_';
  static const String _levelKey = '${_keyPrefix}level';
  static const String _experienceKey = '${_keyPrefix}experience';
  static const String _streakKey = '${_keyPrefix}streak';
  static const String _badgesKey = '${_keyPrefix}badges';
  static const String _tasksCompletedKey = '${_keyPrefix}tasks_completed';
  static const String _lastTaskCompletedKey = '${_keyPrefix}last_task_completed';

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      
      // Initialize default values if they don't exist
      if (!_prefs.containsKey(_levelKey)) {
        await _prefs.setInt(_levelKey, 1);
      }
      if (!_prefs.containsKey(_experienceKey)) {
        await _prefs.setInt(_experienceKey, 0);
      }
      if (!_prefs.containsKey(_streakKey)) {
        await _prefs.setInt(_streakKey, 0);
      }
      if (!_prefs.containsKey(_tasksCompletedKey)) {
        await _prefs.setInt(_tasksCompletedKey, 0);
      }
      if (!_prefs.containsKey(_lastTaskCompletedKey)) {
        await _prefs.setString(_lastTaskCompletedKey, DateTime.now().toIso8601String());
      }
    }
  }

  Future<UserProgress> getUserProgress() async {
    await init();
    return UserProgress(
      level: _prefs.getInt(_levelKey) ?? 1,
      experience: _prefs.getInt(_experienceKey) ?? 0,
      streak: _prefs.getInt(_streakKey) ?? 0,
      badges: _prefs.getStringList(_badgesKey) ?? [],
      tasksCompleted: _prefs.getInt(_tasksCompletedKey) ?? 0,
      lastTaskCompletedAt: DateTime.parse(
        _prefs.getString(_lastTaskCompletedKey) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> saveUserProgress(UserProgress progress) async {
    await init();
    await Future.wait([
      _prefs.setInt(_levelKey, progress.level),
      _prefs.setInt(_experienceKey, progress.experience),
      _prefs.setInt(_streakKey, progress.streak),
      _prefs.setStringList(_badgesKey, progress.badges),
      _prefs.setInt(_tasksCompletedKey, progress.tasksCompleted),
      _prefs.setString(_lastTaskCompletedKey, progress.lastTaskCompletedAt.toIso8601String()),
    ]);
  }

  int calculateExperiencePoints(Task task) {
    int points = 10;
    points *= task.difficulty;
    if (task.completedAt != null && task.completedAt!.isBefore(task.dueDate)) {
      points += 5;
    }
    return points;
  }

  Future<UserProgress> processTaskCompletion(Task task) async {
    UserProgress progress = await getUserProgress();
    
    // Calculate experience points
    int earnedPoints = calculateExperiencePoints(task);
    
    // Update streak
    DateTime now = DateTime.now();
    if (progress.lastTaskCompletedAt.day != now.day) {
      if (now.difference(progress.lastTaskCompletedAt).inDays == 1) {
        progress = progress.copyWith(streak: progress.streak + 1);
      } else {
        progress = progress.copyWith(streak: 1);
      }
    }
    
    // Add experience points and check for level up
    int newExperience = progress.experience + earnedPoints;
    int newLevel = progress.level;
    
    while (newExperience >= progress.experienceToNextLevel) {
      newExperience -= progress.experienceToNextLevel;
      newLevel++;
    }
    
    // Update progress
    progress = progress.copyWith(
      experience: newExperience,
      level: newLevel,
      tasksCompleted: progress.tasksCompleted + 1,
      lastTaskCompletedAt: now,
    );
    
    // Check for new badges
    progress = await _checkAndAwardBadges(progress);
    
    // Save progress
    await saveUserProgress(progress);
    
    return progress;
  }

  Future<UserProgress> _checkAndAwardBadges(UserProgress progress) async {
    List<String> newBadges = List.from(progress.badges);

    if (progress.tasksCompleted >= 100 && !newBadges.contains('Task Master')) {
      newBadges.add('Task Master');
    }
    if (progress.streak >= 7 && !newBadges.contains('Week Warrior')) {
      newBadges.add('Week Warrior');
    }
    if (progress.level >= 10 && !newBadges.contains('Level Pro')) {
      newBadges.add('Level Pro');
    }

    if (newBadges.length != progress.badges.length) {
      progress = progress.copyWith(badges: newBadges);
    }

    return progress;
  }
}
