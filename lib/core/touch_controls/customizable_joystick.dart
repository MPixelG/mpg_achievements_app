import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class CustomizableJoystick extends StatefulWidget {
  final void Function(StickDragDetails details) onJoystickMove;
  const CustomizableJoystick({super.key, required this.onJoystickMove});
  
  @override
  State<StatefulWidget> createState() => _CustomizableJoystickState();
}

class _CustomizableJoystickState extends State<CustomizableJoystick>{
  void Function(StickDragDetails details) get onJoystickMove => widget.onJoystickMove;
  
  _CustomizableJoystickState();
  
  @override
  Widget build(BuildContext context) => Joystick(
    base: JoystickBase(
      decoration: JoystickBaseDecoration(
        middleCircleColor: Colors.red.shade400,
        drawOuterCircle: false,
        drawInnerCircle: false,
        boxShadowColor: Colors.red.shade100,
      ),
    ),
    stick: JoystickStick(
      decoration: JoystickStickDecoration(
        color: Colors.red,
      ),
    ),
    listener: onJoystickMove
  );
}