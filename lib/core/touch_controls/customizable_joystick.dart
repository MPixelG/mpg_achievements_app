import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class CustomizableJoystick extends StatefulWidget {
  final void Function(StickDragDetails details) onJoystickMove;
  final double size;
  final double stickToBaseSizeProportion;
  const CustomizableJoystick({super.key, required this.onJoystickMove, required this.size, this.stickToBaseSizeProportion = 0.35});
  
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
      size: widget.size,
    ),
    includeInitialAnimation: false,
    stick: JoystickStick(
      decoration: JoystickStickDecoration(
        color: Colors.red,
      ),
      size: widget.size * widget.stickToBaseSizeProportion,
    ),
    listener: onJoystickMove,
  );
}