import 'package:flame/components.dart';
import 'package:mpg_achievements_app/util/type_utils.dart';

import 'character_controller.dart';

class ControlActionBundle<T extends Component>{
  final Set<ControlAction<T>> controlActions;
  ControlActionBundle(this.controlActions);


  ControlActionBundle operator&(ControlActionBundle<T> other){
    return ControlActionBundle(controlActions + other.controlActions);
  }
}