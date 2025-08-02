import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


//this dialogueOverlay is added in mpg_pixel_adventure_class
class TextOverlay extends StatelessWidget{
  final PixelAdventure game;
  const TextOverlay({super.key,required this.game});


  @override
  Widget build(BuildContext context) {
    return game.showDialogue ? Container(
        color:  Colors.transparent.withValues(alpha: 0.15),
        child: AnimatedTextKit
          (animatedTexts: [TyperAnimatedText("Text goes here!",
        textStyle: const TextStyle(color: Color.from(alpha: 2, red: 5, green: 6, blue: 7), fontSize: 18, fontFamily: "gameFont"),
        speed: const Duration(milliseconds: 100),

    )
    ],
      isRepeatingAnimation: false,

      onFinished: (){
        print('success texttyping');
        game.showDialogue = false;},
            ),//Animatedtextkit
        ): Container();
    }
}