import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState{idle, running}
enum PlayerDirection{left, right, idle}
//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, KeyboardHandler {

  //String character is required because we want to be able to change our character
  String character;
  //This call gives us the character that is used in the level.dart file
  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required this.character, position}) : super(position: position);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;

  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  //set Playerdirection and variables that are important for Playerdirection
  PlayerDirection playerDirection = PlayerDirection.idle;
  double moveSpeed = 100;
  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();
  bool isFacingRight = true;

  @override
  FutureOr<void> onLoad(){
    //using an underscore is making things private
  _loadAllAnimations();
  return super.onLoad();
  }

  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  void update(double dt) {
    _updatePlayermovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD);

    if (isLeftKeyPressed && isRightKeyPressed){
      playerDirection = PlayerDirection.idle;
    }
    else if(isLeftKeyPressed){
      playerDirection = PlayerDirection.left;
    }
    else if(isRightKeyPressed){
      playerDirection = PlayerDirection.right;
    }
    else{
      playerDirection = PlayerDirection.idle;
    }
    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);

    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
    };

    //set current animation
    current = PlayerState.idle;


  }

  //Body Expression are concise ways of defining methods of function e.g.    int add(int a, int b) => a + b;

 SpriteAnimation _spriteAnimation(String state, int amount) => SpriteAnimation.fromFrameData(game.images.fromCache('Main Characters/$character/$state (32x32).png'), SpriteAnimationData.sequenced(
     //11 image in the Idle.png
       amount: 11,
       stepTime: stepTime,
       textureSize: Vector2.all(32)));



  void _updatePlayermovement(double dt) {
    double dirX = 0.0;
    switch(playerDirection){
      case PlayerDirection.left:
        if(isFacingRight){
          //built-in function in flame
          flipHorizontallyAroundCenter();
          isFacingRight = false;
        }
        dirX -= moveSpeed;
        current = PlayerState.running;
        break;
      case PlayerDirection.right:
        if(!isFacingRight){
          flipHorizontallyAroundCenter();
          isFacingRight = true;
        }
        dirX += moveSpeed;
        current = PlayerState.running;
        break;
      case PlayerDirection.idle:
        current = PlayerState.idle;
        break;
      }

    velocity = Vector2(dirX, 0.0);
    position += velocity*dt;
  }
}