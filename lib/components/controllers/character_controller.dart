import 'package:flame/components.dart';

abstract class CharacterController<T extends Component> extends Component{

  Set<ControlAction<T>> currentlyActiveActions = {};

  CharacterController();

  @override
  void update(double dt) {

    for (var element in currentlyActiveActions) {
      element.run(parent as T);
    }

    super.update(dt);
  }

}

class ControlAction<T extends Component>{
  String name;
  String key;
  void Function(T parent) run;

  ControlAction(this.name, {required this.key, required this.run});
}