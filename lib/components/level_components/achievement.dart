// these are just examples, game should be default
enum AchiementCategories { game, combat, exploration }

class Achievement {
  // essential attributes
  final int id;
  final String name;
  final String description;
  // reward points when getting achievement
  final int points;
  final bool hidden;
  bool isUnlocked;
  // saving time when achievement was unlocked
  DateTime? unlockedAt;
  // goal is the progress required to unlock the achievement
  int? goal;
  int progress;

  // more advanced attributes
  String? iconPath;
  AchiementCategories? category;
  int? reward;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.points = 0,
    this.hidden = false,
    this.isUnlocked = false,
    this.progress = 0,
    this.goal,
    this.unlockedAt,
    this.iconPath,
    this.category,
    this.reward,
  });

  // function to unlock the achivement
  void unlock() {
    if (!isUnlocked) {
      isUnlocked = true;
      unlockedAt = DateTime.now();
    }
  }

  // call when you want the player to be able to do an achievement twice
  void reset() {
    isUnlocked = false;
    unlockedAt = null;
    progress = 0;
  }

  // update progress if you're using the goal attribute
  void updateProgress(int amount) {
    if (goal != null && !isUnlocked) {
      progress += amount;
      if (progress >= goal!) {
        unlock();
      }
    }
  }

  // use if you want to visually display the progress in percent
  double get progressPercent {
    if (goal == null || goal == 0) return isUnlocked ? 1.0 : 0.0;
    return (progress / goal!).clamp(0.0, 1.0);
  }
}
