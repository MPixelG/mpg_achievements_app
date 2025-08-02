/*import 'package:flutter/material.dart';

/// A simple speech bubble widget with customizable text, colors, alignment, and padding.
/// Can be used to show character dialogue, tooltips, or UI hints.
class SpeechBubble extends StatefulWidget {
  final String text; // Text to display inside the bubble
  final Color bubbleColor; // Background color of the bubble
  final Color textColor; // Color of the displayed text
  final EdgeInsetsGeometry padding; // Padding inside the bubble
  final Alignment alignment; // Alignment of the bubble within its parent

  const SpeechBubble({
    super.key,
    required this.text,
    this.bubbleColor = Colors.white,
    this.textColor = Colors.black,
    this.padding = const EdgeInsets.all(8),
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment, // Position the bubble (e.g., top/bottom of parent)
      child: Container(
        padding: padding, // Inner spacing
        margin: const EdgeInsets.all(8), // Margin around the bubble
        decoration: BoxDecoration(
          color: bubbleColor, // Bubble background
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: Text(
          text,
          style: TextStyle(color: textColor), // Text color
        ),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
   print
  }


}
*/
