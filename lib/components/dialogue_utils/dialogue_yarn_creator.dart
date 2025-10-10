import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/state_management/providers/player_state_provider.dart';

import '../../state_management/providers/task_state_provider.dart';

class DialogueYarnCreator extends Component with DialogueView {

  DialogueYarnCreator();

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
      //..commands.addCommand2<String, int>('createTask', createTask)
      ..commands.addCommand0('playeryes', playerYes as FutureOr<void> Function())
      ..commands.addCommand0('playerno', playerNo as FutureOr<void> Function() )
      //..commands.addCommand1<String>('progressStart', taskProvider.notifier.read(node))
      //..commands.addCommand2<String, int>('progressUpdate', progressUpdate) //add providers and methods
      ..parse(script);
    return project;
  }

  void playerYes() {
    if (kDebugMode) {
      print('Yes');
    }
  }

  void playerNo() {
    if (kDebugMode) {
      print('no');
    }
  }

 }

