import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/state_management/models/achievement_data.dart';

final achievementProvider = NotifierProvider<AchievementNotifier, AchievementData>(
  AchievementNotifier.new,);

class AchievementNotifier extends Notifier<AchievementData> {
  @override
  AchievementData build() =>
    // Initialize the player data with default values.
    // This method is called when the provider is first created.
    // You can also fetch initial data from a database or API here.
    // For this example, we are just returning a PlayerData object with a default character name
    AchievementData(name: "test", description: "test");

// increase progress
  void updateProgress([int steps = 1]) {
    if (!state.isCompleted) {
      state.currentSteps += steps;
      if (state.currentSteps >= state.totalSteps) {
        markCompleted();
      }
    }
  }

// completing achievement
  void markCompleted() {
    state.isCompleted = true;
    state.dateCompleted = DateTime.now();
    state.currentSteps = state.totalSteps;
  }

  void reset() {
    state.currentSteps = 0;
    state.isCompleted = false;
    state.dateCompleted = null;
  }

  String getStatus() {
    if (state.isCompleted) return "completed";
    if (state.currentSteps > 0) return "in progress";
    return "not started";
  }
}
/* todo implementation of database get / set etc.
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
factory AchievementData.fromMap(Map<String, dynamic> map) {
return AchievementData(
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
}*/