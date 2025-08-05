import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble_state.dart';


class SpeechBubble extends StatefulWidget {

  //text to display and postion
  final String characterName;
  final String text;

  //Duration between character appearing and text displaying
  final Duration typingSpeed;
  final Duration showDuration;
  final Duration dismissDuration;

  //styling
  final Color textColor;
  final double fontSize;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final bool showTail;
  final bool autoDismiss;
  final bool autoStart;

  //callback
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;



  const SpeechBubble(
      {super.key,
        required this.characterName,
        required this.typingSpeed,
        required this.borderRadius,
        required this.autoDismiss,
        required this.fontSize,
        this.onComplete,
        this.onDismiss,
        required this.padding,
        required this.showDuration,
        required this.showTail,
        required this.textColor, required this.autoStart, required this.text, required this.dismissDuration,
        });




  @override
  State<StatefulWidget> createState() => SpeechBubbleState();
}