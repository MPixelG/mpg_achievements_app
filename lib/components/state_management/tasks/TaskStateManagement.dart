import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

enum TaskState {
  locked,
  available,
  active,
  completed,
  failed,
}

class Task {
  final String id;
  final String description;
  TaskState state;

  int progress;
  final int goal;

  Task({
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

/// ---- RIVERPOD TASK MANAGEMENT ----


class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]);

  /// Task hinzufügen
  void addTask(String description, {int goal = 1}) {
    state = [
      ...state,
      Task(id: uuid.v4(), description: description, goal: goal),
    ];
  }

  /// Task starten
  void startTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..start())   // ruft start() auf, gibt Task zurück
        else
          task
    ];
  }

  /// Fortschritt updaten
  void updateProgress(String id, int amount) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..updateProgress(amount))
        else
          task
    ];
  }

  /// Task direkt abschließen
  void completeTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..complete())
        else
          task
    ];
  }

  /// Task fehlschlagen lassen
  void failTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..fail())
        else
          task
    ];
  }
}

/// Provider global definieren
final taskProvider =
StateNotifierProvider<TaskNotifier, List<Task>>((ref) => TaskNotifier());
