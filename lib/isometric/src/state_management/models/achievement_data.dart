import 'package:uuid/uuid.dart';

var uuid = const Uuid();

enum AchievementState {
  available, completed
}

class AchievementData {
  final String id;
  final String name;
  final String description;
  final String? category;
  final int difficulty; // 1-5
  final String? reward; // variable for storing possible reward to display later
  final DateTime dateCreated;
  final AchievementState state;
  final int totalSteps; // e.g. 3 tasks in total to complete achievement
  int currentSteps; // e.g. 1 of 3 tasks done
  bool isCompleted;
  DateTime? dateCompleted;

  AchievementData({
    String? id,
    DateTime? dateCreated,
    this.state = AchievementState.available,
    required this.name,
    required this.description,
    this.category,
    this.difficulty = 1,
    this.reward,
    this.totalSteps = 1,
    this.currentSteps = 0,
    this.isCompleted = false,
    this.dateCompleted,
  }) : id = const Uuid().v4(),
        dateCreated = DateTime.now();

  AchievementData copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? difficulty,
    String? reward,
    DateTime? dateCreated,
    AchievementState? state,
    int? totalSteps,
    int? currentSteps,
    bool? isCompleted,
    DateTime? dateCompleted,}) => AchievementData(id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      reward: reward ?? this.reward,
      dateCreated: dateCreated ?? this.dateCreated,
      state: state ?? this.state,
      totalSteps: this.totalSteps,
      currentSteps: currentSteps ?? this.currentSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
    );
}






