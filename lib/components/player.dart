import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'traps/saw.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState { idle, running, jumping, falling, hit, appearing, disappearing }

//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>,
        KeyboardHandler,
        CollisionCallbacks,
        HasCollisions{
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

  bool debugFlyMode = false;
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;


  bool hasJumped = false;
  bool gotHit = false;


  //ability to go left or right
  double moveSpeed = 35;

  double horizontalMovement = 0;

  //for debug fly purposes only
  double verticalMovement = 0;


  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();
  //starting position
  Vector2 startingPosition = Vector2.zero();

  //List of collision objects
  List<CollisionBlock> collisionsBlockList = [];

  // because the hitbox is a property of the player it follows the player where ever he goes. Same for the collecables
  RectangleHitbox hitbox = RectangleHitbox(
    position: Vector2(4, 4),
    size: Vector2(24, 28),
  );


  //ground
  bool isOnGround = false;

  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required this.character, super.position});

  @override
  FutureOr<void> onLoad() {
    //using an underscore is making things private
    _loadAllAnimations();
    startingPosition = Vector2(position.x, position.y);
    add(hitbox);
    return super.onLoad();
  }

  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  void update(double dt) {
    if(!gotHit) {
      _updatePlayerstate();
      _updatePlayerMovement(dt);
      //needs to be after checking for collisions
    }
    super.update(dt);
  }

  Vector2 mouseCoords = Vector2.zero();
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    verticalMovement = 0; //debug fly purposes only

    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
            keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

    if (keysPressed.contains(LogicalKeyboardKey.keyR)) _respawn(); //press r to reset player
    if (keysPressed.contains(LogicalKeyboardKey.controlLeft)) debugFlyMode = !debugFlyMode; // press left alt to toggle fly mode
    if (keysPressed.contains(LogicalKeyboardKey.keyX)) print(hitbox.isColliding); //press x to print if the player is currently in a wall
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) debugNoClipMode = !debugNoClipMode; //press C to toggle noClip mode. lets you fall / walk / fly through walls. better only use it whilst flying (ctrl key)
    if (keysPressed.contains(LogicalKeyboardKey.keyT)) position = mouseCoords; //press T to teleport the player to the mouse
    if (keysPressed.contains(LogicalKeyboardKey.keyY)) debugImmortalMode = !debugImmortalMode; //press Y to toggle immortality
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {debugMode = !debugMode; (parent as Level).setDebugMode(debugMode);} //press Y to toggle debug mode (visibility of hitboxes and more)

    //ternary statement if leftkey pressed then add -1 to horizontal movement if not add 0 = not moving
    if(isLeftKeyPressed) horizontalMovement = -1;
    if(isRightKeyPressed) horizontalMovement = 1;

    //if the key is pressed than the player jumps in _updatePlayerMovement
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      if(debugFlyMode) verticalMovement = -1; //when in debug mode move the player upwards
      else hasJumped = true; //else jump
    }

    if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) && debugFlyMode) { //when in fly mode and shift is pressed, the player gets moved down
      verticalMovement = 1;
    }

    return super.onKeyEvent(event, keysPressed);
  }
//checking collisions with an inbuilt method that checks if player is colliding
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the player checks if the hitbox that it is colliding with is a Collectable or saw, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Collectable) other.collidedWithPlayer();
    if (other is Saw && !debugImmortalMode) _respawn();
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
    disappearAnimation = _spriteAnimation(pathRespawn,'Disappearing ', 7, false, texture96file, textureSize96);


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
  void _updatePlayerMovement(double dt) {
    if (hasJumped) if (isOnGround) playerJump(); else hasJumped = false;

    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *= 0.81 * (dt+1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
    position.x += velocity.x * dt;

    if(!debugFlyMode) velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);

    if (debugFlyMode) {
      velocity.y += verticalMovement * moveSpeed * (dt + 1);
      velocity.y *= 0.9;
    }
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

  void playerJump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

  void _respawn() {
    gotHit = true;
    current = PlayerState.hit;
    velocity = Vector2.zero();
    Future.delayed(Duration(milliseconds: 250),(){
      scale.x = 0.33; //flip the player to the right side and a third of the size because the animation is triple of the size
      scale.y = 0.33;
      current = PlayerState.disappearing;
      Future.delayed(Duration(milliseconds: 150),(){
        Future.delayed(Duration(milliseconds: 450),(){
          position = startingPosition;

          current = PlayerState.appearing;
          Future.delayed(Duration(milliseconds: 350),(){
            scale.x = 1;
            scale.y = 1;
            _updatePlayerstate();
            gotHit = false;
          });
        });
      });
    });
  }

  @override
  ShapeHitbox getHitbox() => hitbox;

  @override
  Vector2 getPosition() => position;

  @override
  Vector2 getScale() => scale;

  @override
  Vector2 getVelocity() => velocity;

  @override
  void setIsOnGround(bool val) => isOnGround = val;

  @override
  void setPos(Vector2 newPos) => position = newPos;
}