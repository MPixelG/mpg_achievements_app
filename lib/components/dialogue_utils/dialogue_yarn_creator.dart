import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/state_management/providers/taskStateProvider.dart';

class DialogueYarnCreator extends Component with DialogueView {
  final WidgetRef ref; // <<--- wichtig!
  DialogueYarnCreator(this.ref);

  late YarnProject project;
  late String yarnFilePath;
  late String script;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await loadYarnFile('assets/yarn/test.yarn');
  }


  // Parse the Yarn script into a YarnProject
  Future<YarnProject> loadYarnFile(String yarnfile) async {
    script = await rootBundle.loadString(yarnfile);
    project = YarnProject()
      ..commands.addCommand2<String, int>('createTask', createTask)
      ..commands.addCommand0('playeryes', playeryes as FutureOr<void> Function())
      ..commands.addCommand0('playerno', playerno as FutureOr<void> Function() )
      ..commands.addCommand1<String>('progressStart', progressStart)
      ..commands.addCommand2<String, int>('progressUpdate', progressUpdate)
      ..parse(script);
    return project;
  }

  void playeryes() {
    print('Yes');
  }

  void playerno() {
    print('no');
  }

  void progressStart(String taskDesc) {
    ref.read(taskProvider.notifier).startTaskByDescription(taskDesc);
  }

  void progressUpdate(String taskId, int amount) {
    ref.read(taskProvider.notifier).updateProgressByDescription(taskId, amount);
  }
  void createTask(String description, int goal) {
    ref.read(taskProvider.notifier).addTask(description, goal: goal);
  }
}

