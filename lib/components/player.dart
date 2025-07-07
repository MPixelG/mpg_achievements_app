import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/custom_hitbox.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState { idle, running, jumping, falling }

//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  //String character is required because we want to be able to change our character
  String character;
  //This call gives us the character that is used in the level.dart file
  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required this.character, super.position});

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  //gravity variables
  final double _gravity = 15.0;
  final double _jumpForce = 320;
  final double _terminalVelocity = 300;

  bool hasjumped = false;

  //ability to go left or right
  double horizontalMovement = 0;
  double moveSpeed = 100;

  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();

  //List of collision objects
  List<CollisionBlock> collisionsBlockList = [];

  // because the hitbox is a property of the player it follows the player whereever he goes. Same for the collecables
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  //ground
  bool isOnGround = false;

  @override
  FutureOr<void> onLoad() {
    //using an underscore is making things private
    _loadAllAnimations();
    debugMode = false;
    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
      ),
    );
    return super.onLoad();
  }

  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  void update(double dt) {
    _updatePlayerstate();
    _updatePlayermovement(dt);
    _checkHorizontalCollisions();
    //needs to be after checking for collisions
    _addGravity(dt);
    _checkVerticalCollisions();
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

    //ternary statement if leftkey pressed then add -1 to horizontal movement if not add 0 = not moving
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;
    //if the key is pressed than the player jumps in _updatePlayerMovement
    hasjumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }
//checking collisions with an inbuilt method that checks if player is colliding
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //her the player checks if the hitbox that it is colliding with is a Collectable, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Collectable) other.collidedWithPlayer();
    super.onCollision(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    fallingAnimation = _spriteAnimation('Fall', 1);
    jumpingAnimation = _spriteAnimation('Jump', 1);

    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
    };

    //set current animation
    current = PlayerState.idle;
  }

  //Body Expression are concise ways of defining methods of function e.g.    int add(int a, int b) => a + b;

  SpriteAnimation _spriteAnimation(String state, int amount) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('Main Characters/$character/$state (32x32).png'),
        SpriteAnimationData.sequenced(
          //11 image in the Idle.png
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(32),
        ),
      );

  //only handles x movement for player
  void _updatePlayermovement(double dt) {
    if (hasjumped && isOnGround) _playerJump(dt);

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _checkHorizontalCollisions() {
    //we are iterating through our obstacles
    for (final block in collisionsBlockList) {
      //because we do not want to interact with our platforms in horizontal movements, we first check if our obstacle is a platform if not we check for collisions with our util function _checkCollision
      if (!block.isPlatform) {
        //this refers to our player
        if (checkCollision(this, block)) {
          //if we are going to the right
          if (velocity.x > 0) {
            // we stop
            velocity.x = 0;
            // and we change position to stop at block.x minus width of our hitbox and the offset of our hitbox
            position.x = block.x - hitbox.offsetX - hitbox.width;
          }
          //if we are going to the left
          else if (velocity.x < 0) {
            //stop
            velocity.x = 0;
            //new position should be player position + width of hitbox + offsetX
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
          }
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

  void _checkVerticalCollisions() {
    for (final block in collisionsBlockList) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          //we don't want to check if the top of the player is hitting the bottom of a platform, but only if the bottom of our player is touching the top of our platform
          //see fixedY in utils.dart
          if (velocity.y > 0) {
            velocity.y = 0;
            //chenge to hitbox values
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
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
  }

  //handles animations and states
  void _updatePlayerstate() {
    PlayerState playerState = PlayerState.idle;

    //if we are going to the right and facing left flip us and the other way round
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 0 || velocity.x < 0) {
      playerState = PlayerState.running;
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 0) playerState = PlayerState.falling;

    if (velocity.y < 0) playerState = PlayerState.jumping;

    //here the animation ist set after checking all of the conditions above
    current = playerState;
  }

  void _playerJump(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasjumped = false;
  }
}
