
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

class DialogueYarnCreator extends Component with DialogueView {

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
      ..commands.addCommand0('playeryes', playeryes as FutureOr<void> Function())
      ..commands.addCommand0('playerno', playerno as FutureOr<void> Function() )
      ..parse(script);
    return project;
  }

  void playeryes() {
    print('Yes');
  }

  void playerno() {
    print('no');
      }
  }






