import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble_state.dart';


class SpeechBubble extends StatefulWidget {

  //text to display and postion
  final String text;
  final double xPosition;
  final double yPosition;
  //Current position of the character
  final Offset targetPosition;
  //offset from character(i.e. y/x position from head
  final Offset bubbleOffset;

  //Duration between character appearing and text displaying
  final Duration typingSpeed;
  final Duration showDuration;

  //styling
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showTail;
  final bool autoDismiss;

  //callback
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;

  SpeechBubble(
      {super.key,
        required this.text,
        required this.typingSpeed,
        required this.borderRadius,
        required this.autoDismiss,
        required this.fontSize,
        this.onComplete,
        this.onDismiss,
        required this.padding,
        required this.showDuration,
        required this.showTail,
        required this.textColor,
        required this.xPosition,
        required this.yPosition,
        required this.targetPosition,
        required this.bubbleOffset,});




  @override
  State<StatefulWidget> createState() => SpeechBubbleState();
}