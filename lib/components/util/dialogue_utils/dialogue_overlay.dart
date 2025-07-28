import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


//this dialogueOverlay is added in mpg_pixel_adventure_class
class DialogueOverlay extends StatelessWidget{
  final PixelAdventure game;
  const DialogueOverlay({super.key,required this.game});


  @override
  Widget build(BuildContext context) {
    return game.showDialogue ? Container(
        color: const Color.fromRGBO(167, 218, 218, 50),
        child: AnimatedTextKit
          (animatedTexts: [TyperAnimatedText("Text goes here!",
        textStyle: const TextStyle(color: Color.fromRGBO(0, 0, 0,100), fontSize: 18),
        speed: const Duration(milliseconds: 100)
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