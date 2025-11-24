import 'package:flame/components.dart';
import 'package:flutter/services.dart';

abstract class CharacterController<T extends Component> extends Component{

  Set<ControlAction<T>> currentlyActiveActions = {};

  CharacterController();

  @override
  void update(double dt) {
    //the characterController loops through all active actions and runs them, it takes the name of the action and runs it with GameCharacter passed on as parent
    // this way the ControlAction in the player sets the velocity in GameCharacter and lets the player move by adding velocity to its isoPosition
    for (var element in currentlyActiveActions) {
      element.run(parent as T);
    }

    super.update(dt);
  }

}
/// controlAction scaffolding for controlling the player
class ControlAction<T extends Component>{
  String name;
  LogicalKeyboardKey key;
  void Function(T parent) run;

  ControlAction(this.name, {required this.key, required this.run});
}