import 'package:uuid/uuid.dart';

var uuid = Uuid();

enum TaskState {
  locked,
  available,
  active,
  completed,
  failed,
}

class TaskData {
  final String id;
  final String description;
  TaskState state;
  int progress;
  final int goal;

  TaskData({
    String? id,
    required this.description,
    this.state = TaskState.available,
    this.progress = 0,
    this.goal = 1,
  }): id = id ?? uuid.v4();


  TaskData copyWith({
    String? id,
    String? description,
    int? goal,
    int? progress,
    TaskState? status,}){

    return TaskData(id: id ?? this.id,
        description: description ?? this.description,
    goal: goal ?? this.goal,
    progress: progress ?? this.progress,
    state: state);
  }

  void start() {
    if (state == TaskState.available) {
      state = TaskState.active;
    }
  }

  void updateProgress(int amount) {
    if (state == TaskState.active) {
      progress += amount;
      if (progress >= goal) {
        complete();
      }
    }
  }

  void complete() {
    if (state == TaskState.active) {
      state = TaskState.completed;
    }
  }

  void fail() {
    if (state == TaskState.active) {
      state = TaskState.failed;
    }
  }
}
