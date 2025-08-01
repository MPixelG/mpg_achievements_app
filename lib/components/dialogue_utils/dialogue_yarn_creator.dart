
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

class DialogueYarnCreator extends Component with DialogueView {

  late YarnProject _project;
  late String _yarnFilePath;
  late String _script;


  @override
  Future<void> onLoad() async {
    await super.onLoad();

  }
// Parse the Yarn script into a YarnProject
  Future<YarnProject> _loadYarnFile(String yarnfile) async {
    final yarntest = '''
      <<character "Task" Board>>
      <<character "Player" Player>>
      
      title: Start
      ---
      <<if visited('Board1')>>
      Board: Hello there!
      -> How are you?
      <<jump>>
      -> Go away!
      <<give>>
      ===
      title: Happy
      ---
      Board: I'm glad to hear that!
      ===
      title: Angry
      ---
      Board: Oh... sorry to bother you.
      ===
    ''';

    _project = YarnProject()
      ..commands.addCommand1('jump', _jump as FutureOr<void> Function(dynamic p1))
      ..commands.addCommand1('give', _give as FutureOr<void> Function(dynamic p1))
      ..parse(yarntest);



    return _project;
  }

  void _jump() {
    print('Jump');
  }

  void _give() {
    print('give');
      }

      Future<YarnProject> get yarn_project async {
    return _project;
      }

      Future<String> get script async {
     return _script;
      }

      Future<String> get yarnpath async {
    return _yarnFilePath;
      }

}






