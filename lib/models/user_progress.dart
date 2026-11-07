class UserProgress {
  final int level;
  final int currentLevelPoints;
  final int pointsToNextLevel;

  const UserProgress({
    this.level = 1,
    this.currentLevelPoints = 0,
    this.pointsToNextLevel = 100,
  });

  /// بيضيف نقاط، ولو عدّى حد المستوى بيرفعك مستوى (وكل مستوى أصعب بـ 50 نقطة).
  UserProgress addPoints(int points) {
    var lvl = level;
    var current = currentLevelPoints + points;
    var need = pointsToNextLevel;
    while (current >= need) {
      current -= need;
      lvl++;
      need += 50;
    }
    return UserProgress(
      level: lvl,
      currentLevelPoints: current,
      pointsToNextLevel: need,
    );
  }

  Map<String, dynamic> toMap() => {
        'level': level,
        'currentLevelPoints': currentLevelPoints,
        'pointsToNextLevel': pointsToNextLevel,
      };

  factory UserProgress.fromMap(Map<String, dynamic> m) => UserProgress(
        level: m['level'] as int,
        currentLevelPoints: m['currentLevelPoints'] as int,
        pointsToNextLevel: m['pointsToNextLevel'] as int,
      );
}