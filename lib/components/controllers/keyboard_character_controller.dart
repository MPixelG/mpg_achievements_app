import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/controllers/character_controller.dart';

class KeyboardCharacterController extends CharacterController with KeyboardHandler{
  KeyboardCharacterController();

  //todo replace with json file
  static Map<String, ControlAction> keyBindings = {
    "W": ControlAction.moveUp,
    "A": ControlAction.moveLeft,
    "S": ControlAction.moveDown,
    "D": ControlAction.moveRight,
    "R": ControlAction.dRespawn,
    "Y": ControlAction.dImmortal,
    "C": ControlAction.dNoClip,
    "H": ControlAction.dShowGuiEditor
  };

  static Set<ControlAction> currentlyActiveActions = {};

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if(event is KeyUpEvent || event is KeyDownEvent) {
      Set<ControlAction?> mappedActions = keysPressed.map<ControlAction?>((e) => keyBindings[e.keyLabel]).toSet()..removeWhere((element) => element == null);
      currentlyActiveActions = mappedActions.map((e) => e!).toSet();
    }
    return super.onKeyEvent(event, keysPressed);
  }


}