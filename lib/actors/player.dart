import 'dart:async';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState{idle, running}
//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure> {

  late final SpriteAnimation idleAnimation;
  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  @override
  FutureOr<void> onLoad(){
    //using an underscore is making things private
  _loadAllAnimations();
  return super.onLoad();
  }

  void _loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning
    idleAnimation = SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/Ninja Frog/Idle (32x32).png'), SpriteAnimationData.sequenced(
        //11 image in the Idle.png
        amount: 11,
        stepTime: stepTime,
        textureSize: Vector2.all(32)));

    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      PlayerState.idle: idleAnimation};

    //set current animation
    current = PlayerState.idle;


  }
}