import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/custom_hitbox.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/player_hitbox.dart';
import 'package:mpg_achievements_app/components/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'saw.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState { idle, running, jumping, falling, hit, appearing, disappearing }

//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  //String character is required because we want to be able to change our character
  String character;
  String pathRespawn = 'Main Characters/';
  late String pathPlayer = 'Main Characters/$character/';


  //needs to be cleaned up, this is just a quick an dirty way to make loading animations mor adaptable
  double textureSize32 = 32;
  double textureSize96 = 96;
  String texture32file = '(32x32).png';
  String texture96file = '(96x96).png';


  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearAnimation;
  late final SpriteAnimation disappearAnimation;
  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  //gravity variables
  final double _gravity = 15.0;
  final double _jumpForce = 320;
  final double _terminalVelocity = 300;

  bool hasJumped = false;
  bool gotHit = false;

  //ability to go left or right
  double moveSpeed = 35;

  double horizontalMovement = 0;

  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();
  //starting position
  Vector2 startingPosition = Vector2.zero();

  //List of collision objects
  List<CollisionBlock> collisionsBlockList = [];

  // because the hitbox is a property of the player it follows the player where ever he goes. Same for the collecables
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  late PlayerHitbox playerHitbox;


  //ground
  bool isOnGround = false;

  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required this.character, super.position}){playerHitbox = PlayerHitbox(this);}

  @override
  FutureOr<void> onLoad() {
    //using an underscore is making things private
    _loadAllAnimations();
    startingPosition = Vector2(position.x, position.y);
    debugMode = true;

    playerHitbox = PlayerHitbox(this);
    
    add(playerHitbox.leftFoot);
    add(playerHitbox.rightFoot);
    add(playerHitbox.head);
    add(playerHitbox.body);

    playerHitbox.body.onCollisionCallback = (intersectionPoints, other) {
      if (other.parent is CollisionBlock) _checkHorizontalCollisions(other.parent as CollisionBlock);
    };
    playerHitbox.head.onCollisionCallback = (intersectionPoints, other) {
      if (other.parent is CollisionBlock) _checkHorizontalCollisions(other.parent as CollisionBlock);
    };
    playerHitbox.rightFoot.onCollisionCallback = (intersectionPoints, other) {
      if ((other) is CollisionBlock) _checkVerticalCollisions(other.parent as CollisionBlock);
    };
    playerHitbox.leftFoot.onCollisionCallback = (intersectionPoints, other) {
      if (other.parent is CollisionBlock) _checkVerticalCollisions(other.parent as CollisionBlock);
    };

  }

  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  void update(double dt) {
    if(!gotHit){
    _updatePlayerstate();
    _updatePlayermovement(dt);
    //needs to be after checking for collisions
    _addGravity(dt);}
    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);

    if (keysPressed.contains(LogicalKeyboardKey.keyR)) _respawn(); //r zum resetten drücken

    //ternary statement if leftkey pressed then add -1 to horizontal movement if not add 0 = not moving
    if(isLeftKeyPressed) horizontalMovement = -1;
    if(isRightKeyPressed) horizontalMovement = 1;

    //if the key is pressed than the player jumps in _updatePlayerMovement
    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }
//checking collisions with an inbuilt method that checks if player is colliding
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the player checks if the hitbox that it is colliding with is a Collectable or saw, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Collectable) other.collidedWithPlayer();
    if (other is Saw) _respawn();
    super.onCollision(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning -> needs to be cleaned up only quick and dirty fix
    idleAnimation = _spriteAnimation(pathPlayer,'Idle ', 11, true, texture32file, textureSize32);
    runningAnimation = _spriteAnimation(pathPlayer,'Run ', 12, true, texture32file, textureSize32);
    fallingAnimation = _spriteAnimation(pathPlayer,'Fall ', 1, true, texture32file, textureSize32);
    jumpingAnimation = _spriteAnimation(pathPlayer,'Jump ', 1, true, texture32file, textureSize32);
    hitAnimation = _spriteAnimation(pathPlayer,'Hit ', 7, false, texture32file, textureSize32);
    appearAnimation = _spriteAnimation(pathRespawn,'Appearing ', 7, false, texture96file, textureSize96);
    disappearAnimation = _spriteAnimation(pathRespawn,'Desappearing ', 7, false, texture96file, textureSize96);


    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearAnimation,
      PlayerState.disappearing: disappearAnimation,

    };

    //set current animation
    current = PlayerState.idle;
  }

  //Body Expression are concise ways of defining methods of function e.g.    int add(int a, int b) => a + b;
  //loop gets passed in to say if animation should be looped or not, e.g. hit should only be played once -> loop = false
  SpriteAnimation _spriteAnimation(String path, String state, int amount, bool loop, String fileName, double textureSize) =>
    SpriteAnimation.fromFrameData(
      game.images.fromCache('$path$state$fileName' ),
      SpriteAnimationData.sequenced(
        //11 image in the Idle.png
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(textureSize),
        loop: loop,
      ),
    );

  //only handles x movement for player
  void _updatePlayermovement(double dt) {
    if (hasJumped && isOnGround) playerJump(dt);

    velocity.x += horizontalMovement * moveSpeed;

    position.x += velocity.x * dt;
    velocity.x *= 0.81 * (dt+1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
    if (abs(velocity.x) < 0.3) velocity.x = 0; // set the velocity to 0 as soon as it gets too small
  }

  void _checkHorizontalCollisions(CollisionBlock block) {
    //we are iterating through our obstacles
      //because we do not want to interact with our platforms in horizontal movements, we first check if our obstacle is a platform if not we check for collisions with our util function _checkCollision
      if (!block.isPlatform) {
        //this refers to our player
        //checkCollision defined in utils.dart
        if (checkCollision(this, block)) {
          //if we are going to the right
          if (velocity.x > 0) {
            velocity.x = 0;
            //we stop
            //and we change position to stop at block.x minus width of our hitbox and the offset of our hitbox
            double newPos = block.x - hitbox.offsetX - hitbox.width; //TODO replace all old hitbox vars with the new player hitbox vars and remove the old one
            position.x = newPos;
          }
          //if we are going to the left
          else if (velocity.x < 0) {
            velocity.x = 0;
            //stop
            //new position should be player position + width of hitbox + offsetX
            double newPos = block.x + block.width + hitbox.width + hitbox.offsetX;
            position.x = newPos;
          }
        }
      }
  }


  void _checkVerticalCollisions( block) {

      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          //we don't want to check if the top of the player is hitting the bottom of a platform, but only if the bottom of our player is touching the top of our platform
          //see fixedY in utils.dart
          if (velocity.y > 0) {
            velocity.y = 0;
            //change to hitbox values
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          //if the character is falling
          if (velocity.y > 0) {
            //stop
            velocity.y = 0;
            //position set to block.y - hitbox.height - hitbox.offsetY
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
          }
          //if character is jumping
          if (velocity.y < 0) {
            //stop
            velocity.y = 0;
            //same for jump procedure
            position.y = block.y + block.height - hitbox.offsetY;
          }
        }
      }

  }

  //gravity adds to our Y-velocity, we need deltatime again here to account for Framerate
  void _addGravity(double dt) {
    velocity.y += _gravity;
    //here we set a limit to our y-velocity which is our jumpforce for going up, and our terminal velocity for falling
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    //here you change y position according to velocity times deltatime to adjust for clockspeed
    position.y += velocity.y * dt;
  }

  //handles animations and states
  void _updatePlayerstate() {
    PlayerState playerState = PlayerState.idle;

    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    if (velocity.x < -3 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 3 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 3 || velocity.x < -3) {
      playerState = PlayerState.running;
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 0) playerState = PlayerState.falling;

    if (velocity.y < 0) playerState = PlayerState.jumping;

    //here the animation ist set after checking all of the conditions above
    current = playerState;
  }

  void playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

  void _respawn() {
    gotHit = true;
    current = PlayerState.hit;
    velocity = Vector2.zero();
    //not time to fix animations needs to be done
    Future.delayed(Duration(milliseconds: 350),(){
        current = PlayerState.disappearing;
        Future.delayed(Duration(milliseconds: 350),(){
            Future.delayed(Duration(milliseconds: 350),(){
                position = startingPosition;
                current = PlayerState.appearing;
                scale.x = 1;
                _updatePlayerstate();
                gotHit = false;
            });
        });
    });
  }
}

