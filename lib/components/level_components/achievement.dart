import 'package:uuid/uuid.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String? category;
  final int difficulty; // 1-5
  final String? reward; // variable for storing possible reward to display later
  final DateTime dateCreated;

  final int totalSteps; // e.g. 3 tasks in total to complete achievement
  int currentSteps; // e.g. 1 of 3 tasks done
  bool isCompleted;
  DateTime? dateCompleted;

  Achievement({
    required this.name,
    required this.description,
    this.category,
    this.difficulty = 1,
    this.reward,
    this.totalSteps = 1,
  }) : id = const Uuid().v4(),
       dateCreated = DateTime.now(),
       currentSteps = 0,
       isCompleted = false,
       dateCompleted = null;

  // increase progress
  void updateProgress([int steps = 1]) {
    if (!isCompleted) {
      currentSteps += steps;
      if (currentSteps >= totalSteps) {
        markCompleted();
      }
    }
  }

  // completing achievement
  void markCompleted() {
    isCompleted = true;
    dateCompleted = DateTime.now();
    currentSteps = totalSteps;
  }

  void reset() {
    currentSteps = 0;
    isCompleted = false;
    dateCompleted = null;
  }

  String getStatus() {
    if (isCompleted) return "completed";
    if (currentSteps > 0) return "in progress";
    return "not started";
  }

  // export parameters as a Map
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "category": category,
      "difficulty": difficulty,
      "reward": reward,
      "dateCreated": dateCreated.toIso8601String(),
      "dateCompleted": dateCompleted?.toIso8601String(),
      "isCompleted": isCompleted,
      "progress": "$currentSteps/$totalSteps",
    };
  }

  /// import from Map
  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
        name: map["name"],
        description: map["description"],
        category: map["category"],
        difficulty: map["difficulty"] ?? 1,
        reward: map["reward"],
        totalSteps: int.tryParse(map["progress"]?.split("/")?.last ?? "1") ?? 1,
      )
      ..currentSteps =
          int.tryParse(map["progress"]?.split("/")?.first ?? "0") ?? 0
      ..isCompleted = map["isCompleted"] ?? false
      ..dateCompleted = map["dateCompleted"] != null
          ? DateTime.parse(map["dateCompleted"])
          : null;
  }
}
