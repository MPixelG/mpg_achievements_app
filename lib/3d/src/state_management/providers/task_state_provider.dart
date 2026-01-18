import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/task_data.dart';



// Provider global definieren //todo Logik mit Liste?
final taskProvider =  NotifierProvider<TaskNotifier, List<TaskData>> (TaskNotifier.new);

class TaskNotifier extends Notifier<List<TaskData>> {

  @override
  List<TaskData> build() => [];


  /// Task hinzufügen
  void addTask(String description, {int goal = 1}) {
    state = [
      ...state,
      TaskData(id: uuid.v4(), description: description, goal: goal),
    ];
  }

  /// Task starten
  void startTask(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..start()) // ruft start() auf, gibt Task zurück
        else
          task
    ];
  }

  void startTaskByDescription(String description) {
    state = [
      for (final task in state)
        if (task.description == description) (task..start()) else task
    ];
  }


  // Fortschritt updaten
  void updateProgress(String id, int amount) {
    state = [
      for (final task in state)
        if (task.id == id)
          (task..updateProgress(amount))
        else
          task
    ];
  }

  void updateProgressByDescription(String description, int amount) {
    state = [
      for (final task in state)
        if (task.description == description) (task..updateProgress(amount)) else task
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

