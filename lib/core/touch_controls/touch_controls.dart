import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:mpg_achievements_app/core/touch_controls/customizable_joystick.dart';

class TouchControls extends StatefulWidget {
  final void Function(StickDragDetails details) onJoystickMove;
  const TouchControls({super.key, required this.onJoystickMove});

  @override
  State<StatefulWidget> createState() => TouchControlState();
}

class TouchControlState extends State<TouchControls> {
  
  Vector2 joystickPos = Vector2(0.028, 0.8);
  double joystickSize = 0.3;
  
  @override
  Widget build(BuildContext context) => Stack(children: [
      Positioned(
        left: joystickPos.x * MediaQuery.widthOf(context),
        top: (joystickPos.y - joystickSize*0.5) * MediaQuery.heightOf(context),
        child: CustomizableJoystick(
          onJoystickMove: widget.onJoystickMove,
          size: joystickSize * MediaQuery.heightOf(context),
        )

      )
    ]);
}