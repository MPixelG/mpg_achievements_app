import 'package:flutter/material.dart';

class PixelButton extends StatefulWidget {
  final String text; //the text of the button
  final VoidCallback? onPressed; //the action when pressed
  final bool mouseHover = false; //if theres a mouse hovering over it

  const PixelButton({
    super.key,
    required this.text,
    this.onPressed,
  }); //basic constructor

  @override
  State<StatefulWidget> createState() => _PixelButtonState(); //the style of the button
}

class _PixelButtonState extends State<PixelButton> {
  bool isPressed = false; //if its being pressed rn
  bool hover = false; //if theres a mouse hovering over it

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      //for hover detection
      onEnter: (_) => setState(
        () => hover = true,
      ), //if you enter the button with your mouse, hover is set to true
      onExit: (_) =>
          setState(() => hover = false), //if you leave it, its set to false

      child: GestureDetector(
        //for clicking detection
        onTapDown: (_) => setState(
          () => isPressed = true,
        ), //if started to click, press is set to true
        onTapUp: (_) => setState(
          () => isPressed = false,
        ), // if you stopped to click, press is set to false
        onTapCancel: () => setState(
          () => isPressed = false,
        ), //if you dragged away from the button, its set to false
        onTap: widget
            .onPressed, //when you press, the action of the button is executed
        child: AnimatedContainer(
          //a container including text and background and stuff thats animatable
          duration: Duration(
            milliseconds: 70,
          ), //the duration of the animation when hovering
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), //the size of the button for the gradient
          decoration: BoxDecoration(
            gradient: LinearGradient(
              //add a gradient
              colors: _getGradientColors(), //with the defined colors
              begin: Alignment.topLeft, //from the top left of the button
              end: Alignment.bottomRight, //to the bottom right of the button
            ),
            border: Border.all(
              // add borders
              color: _getBorderColor(), //with the defined colors
              width: 2, //and a stroke width of 2
            ),
            borderRadius: BorderRadius.circular(
              4,
            ), //the animation container has a bigger border radius
            boxShadow: _getShadow(), //and we add a shadow we defined
          ),
          child: Text(
            //some more customization for the text
            widget.text, //put the text of the button in it
            style: TextStyle(
              //with a given style
              color: Colors.white, //a white text color
              fontSize: 14, //, a font size of 14
              fontWeight:
                  FontWeight.bold, //and in bold, so that its more visible
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (isPressed) {
      return [Color(0xFF3A7BC8), Color(0xFF2E5F9A)]; //light and dark blue
    } else if (hover) {
      return [
        Color(0xFF6BB3FF),
        Color(0xFF5AA3F0),
      ]; // some lighter versions for the hover animations
    } else {
      return [
        Color(0xFF5AA3F0),
        Color(0xFF4A90E2),
      ]; //and some blue tones if it isnt pressed or hovered
    }
  }

  Color _getBorderColor() {
    //some colors for the borders with bit of contrast to the other colors
    if (isPressed)
      return Color(0xFF2E5F9A); //if its pressed, its pretty dark blue
    if (hover)
      return Color(0xFF7BC4FF); // or really light blue when its being hovered
    return Color(0xFF6BB3FF); //or sth in the middle for the regular state
  }

  List<BoxShadow> _getShadow() {
    //the shadow when its hovered
    if (isPressed)
      return []; //if its pressed, we dont want a shadow bc its dark then
    if (hover) {
      //if its hovered, we add a shadow
      return [
        BoxShadow(
          //just a regular a box shadow
          color: Color(
            0xFF7BC4FF,
          ).withValues(alpha: .3), //light transparent blue
          offset: Offset(0, 0), //with no offset
          blurRadius: 18, //and a big blur radius
          spreadRadius:
              2, //and a smaller spread, so that it appears a bit circular
        ),
        BoxShadow(
          color: Color(
            0xFF1A1A1A,
          ), //add a black one with a bit of offset, so that it seems to have a little 3d effect
          offset: Offset(2, 2), //just a small offset
          blurRadius: 0, //and no blur radius
        ),
      ];
    }
    return [
      BoxShadow(
        //if its pressed, we just want a little black shadow to give a 3d effect
        color: Color(0xFF1A1A1A), //dark grey
        offset: Offset(2, 2), //with a bit of offset
        blurRadius: 0, //and no blur radius
      ),
    ];
  }
}
