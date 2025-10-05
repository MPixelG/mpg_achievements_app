import 'dart:async';

import 'package:mpg_achievements_app/components/controllers/keyboard_character_controller.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';

class TestPlayer extends IsoPositionComponent {

  KeyboardCharacterController controller = KeyboardCharacterController();

  @override
  FutureOr<void> onLoad() {
    add(controller);
    return super.onLoad();
  }
}