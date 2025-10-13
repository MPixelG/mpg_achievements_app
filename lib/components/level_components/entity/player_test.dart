import 'dart:async';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/controllers/character_controller.dart';
import 'package:mpg_achievements_app/components/controllers/control_action_bundle.dart';
import 'package:mpg_achievements_app/components/controllers/keyboard_character_controller.dart';
import 'package:mpg_achievements_app/components/level_components/entity/isometric_player.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';
/*
class TestPlayer extends IsometricPlayer{

  late KeyboardCharacterController<TestPlayer> controller;

  TestPlayer({required super.playerCharacter}){
    controller = KeyboardCharacterController(buildControlBundle());
  }

  @override
  Future<void> onLoad() async {
    add(controller);
    return super.onLoad();
  }


  @override
  ControlActionBundle<TestPlayer> buildControlBundle(){
    return ControlActionBundle<TestPlayer>({
      ControlAction("moveUp", key: "W", run: (parent) => parent.velocity.y--),
      ControlAction("moveLeft", key: "A", run: (parent) => parent.velocity.x--),
      ControlAction("moveDown", key: "S", run: (parent) => parent.velocity.z++),
      ControlAction("moveRight", key: "D", run: (parent) {
        parent.velocity.x++;
      }),
    });
  }
}*/