import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.id,
    required this.description,
    this.state = TaskState.available,
    this.progress = 0,
    this.goal = 1,
  });

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
