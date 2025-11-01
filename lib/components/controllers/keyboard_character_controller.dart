import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/controllers/character_controller.dart';

import 'control_action_bundle.dart';

class KeyboardCharacterController<T extends Component> extends CharacterController<T> with KeyboardHandler{
  KeyboardCharacterController(this.actionBundle);
  ControlActionBundle<T> actionBundle;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if(event is KeyUpEvent || event is KeyDownEvent) {
      final Set<String> pressedKeyNames = keysPressed.map((e) => e.keyLabel).toSet();
      //every key pressed and assigned to an action is added to the currentlyActiveActions
      currentlyActiveActions = actionBundle.controlActions.where((element) =>
          pressedKeyNames.contains(element.key)).toSet();
    }

    return super.onKeyEvent(event, keysPressed);
  }
}