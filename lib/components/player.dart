import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState{idle, running}

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
  //ability to go left or right
  double horizontalMovement = 0;
  double moveSpeed = 100;
  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionsBlockList =[];


  @override
  FutureOr<void> onLoad(){
    //using an underscore is making things private
  _loadAllAnimations();
  debugMode = true;
  return super.onLoad();
  }

  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  void update(double dt) {
    _updatePlayerstate();
    _checkHorizontalCollisions();
    _updatePlayermovement(dt);
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.arrowRight) || keysPressed.contains(LogicalKeyboardKey.keyD);

    //ternary statement if leftkey pressed then add -1 to horizontal movement if not add 0 = not moving
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;


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


 //only handles x movement for player
  void _updatePlayermovement(double dt) {

   velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _checkHorizontalCollisions() {

    for(final block in collisionsBlockList){

    }

  }


//handles animations and states
  void _updatePlayerstate() {
    PlayerState playerState = PlayerState.idle;

    //if we are going to the right and facing left flip us and the other way round
    if(velocity.x < 0 && scale.x > 0){
      flipHorizontallyAroundCenter();
    }
    else if(velocity.x > 0 && scale.x < 0){
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 0 || velocity.x < 0){ playerState = PlayerState.running;

    }

    //here the animation ist set after checking all of the conditions above
    current = playerState;
  }


}