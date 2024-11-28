class UserProgress {
  final int level;
  final int experience;
  final int streak;
  final List<String> badges;
  final int tasksCompleted;
  final DateTime lastTaskCompletedAt;

  UserProgress({
    this.level = 1,
    this.experience = 0,
    this.streak = 0,
    List<String>? badges,
    this.tasksCompleted = 0,
    DateTime? lastTaskCompletedAt,
  })  : badges = badges ?? [],
        lastTaskCompletedAt = lastTaskCompletedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'experience': experience,
      'streak': streak,
      'badges': badges,
      'tasksCompleted': tasksCompleted,
      'lastTaskCompletedAt': lastTaskCompletedAt.toIso8601String(),
    };
  }

  static UserProgress fromMap(Map<String, dynamic> map) {
    return UserProgress(
      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
      streak: map['streak'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      tasksCompleted: map['tasksCompleted'] ?? 0,
      lastTaskCompletedAt: map['lastTaskCompletedAt'] != null
          ? DateTime.parse(map['lastTaskCompletedAt'])
          : DateTime.now(),
    );
  }

  UserProgress copyWith({
    int? level,
    int? experience,
    int? streak,
    List<String>? badges,
    int? tasksCompleted,
    DateTime? lastTaskCompletedAt,
  }) {
    return UserProgress(
      level: level ?? this.level,
      experience: experience ?? this.experience,
      streak: streak ?? this.streak,
      badges: badges ?? this.badges,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      lastTaskCompletedAt: lastTaskCompletedAt ?? this.lastTaskCompletedAt,
    );
  }

  int get experienceToNextLevel => level * 100;
  
  bool get canLevelUp => experience >= experienceToNextLevel;
}
