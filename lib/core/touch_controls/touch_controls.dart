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
  @override
  Widget build(BuildContext context) => Stack(children: [
      Positioned(
        child: CustomizableJoystick(
            onJoystickMove: widget.onJoystickMove
        )
      )
    ]);
}