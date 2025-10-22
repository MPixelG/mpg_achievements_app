import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

class YarnCreator extends Component with DialogueView {
  YarnCreator(this.yarnFilePath, {this.commands = const {}});

  final String yarnFilePath;
  late YarnProject project;
  late String script;
  final Map<String, Function> commands;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await loadYarnFile();
  }

  // Parse the Yarn script into a YarnProject
  Future<YarnProject> loadYarnFile() async {
    script = await rootBundle.loadString(yarnFilePath);
    project = YarnProject();
    _registerCommands();
    project.parse(script);
    return project;
  }

void _registerCommands() {
    for (final entry in commands.entries) {
      final name = entry.key;
      final command = entry.value;
      if (command is FutureOr<void> Function()) {
        project.commands.addCommand0(name, command);
      } else if (command is FutureOr<void> Function(String)) {
        project.commands.addCommand1<String>(name, command);
      } else if (command is FutureOr<void> Function(String, String)) {
        project.commands.addCommand2<String, String>(name, command);
      } else if (command is FutureOr<void> Function(int)) {
        project.commands.addCommand1<int>(name, command);
      }
      //more adding possible if necessary
    }
  }
}
