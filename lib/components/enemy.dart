import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/geometry.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/components/traps/saw.dart';
import '../mpg_pixel_adventure.dart';
import 'collectables.dart';
import 'collision_block.dart';
import 'level.dart';

enum EnemyState { idle, running, jumping, falling, hit, appearing, disappearing }

//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Enemy extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>,
        KeyboardHandler,
        CollisionCallbacks,
        HasCollisions{
  //String character is required because we want to be able to change our character
  late String enemyCharacter;

  //reference paths for assests
  late String pathRespawn = 'Main Characters/';
  late String pathPlayer = 'Main Characters/$enemyCharacter/';


  //needs to be cleaned up, this is just a quick an dirty way to make loading animations mor adaptable
  double textureSize32 = 32;
  double textureSize96 = 96;
  String texture32file = '(32x32).png';
  String texture96file = '(96x96).png';

  //animations for each possible player states, they are loaded in the _loadAllanimations() method
  late final SpriteAnimation e_idleAnimation;
  late final SpriteAnimation e_runningAnimation;
  late final SpriteAnimation e_jumpingAnimation;
  late final SpriteAnimation e_fallingAnimation;
  late final SpriteAnimation e_hitAnimation;
  late final SpriteAnimation e_appearAnimation;
  late final SpriteAnimation e_disappearAnimation;

  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  //gravity variables
  final double _gravity = 15.0; //gravity acceleration
  final double _jumpForce = 320; //jump height
  final double _terminalVelocity = 300; //max falling speed

  //track mouse coordinates if needed for teleportation
  Vector2 mouseCoords = Vector2.zero();

  //action states
  bool hasJumped = false; //true when jump
  bool gotHit = false; //true when collision with obstacle


  //ability to go left or right
  double moveSpeed = 35;
  double horizontalMovement = 0;

  //for debug fly purposes only
  //debug switches for special modes
  bool debugFlyMode = false;
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;
  double verticalMovement = 0;


  //set velocity to x=0 and y=0
  Vector2 velocity = Vector2.zero();

  //starting position
  Vector2 startingPosition = Vector2.zero();

  //List of collision objects
  List<CollisionBlock> collisionsBlockList = [];

  // because the hitbox is a property of the player it follows the player where ever he goes. Same for the collectables
  RectangleHitbox hitbox = RectangleHitbox(
    position: Vector2(4, 6),
    size: Vector2(24, 26),
  );


  //is the player standing on the ground or a platform
  bool isOnGround = false;

  //variables for raycasting
  Ray2? ray;
  Ray2? reflection;
  late Vector2 rayOriginPoint = absolutePosition;
  final Vector2 rayDirection = Vector2(1,0);
  @override
  late Paint paint;

  static const numberOfRays = 1000;
  final List<Ray2> rays = [];
  final List<RaycastResult<ShapeHitbox>> results = [];
  final safetyDistance = 50;




  //constructor super is reference to the SpriteanimationGroupComponent above, which contains position as attributes
  Enemy({required this.enemyCharacter, super.position, super.anchor = Anchor.center});

  @override
  FutureOr<void> onLoad() {

    //raycasting
    paint = BasicPalette.red.paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    //using an underscore is making things private
    _loadAllAnimations();
    startingPosition = Vector2(position.x, position.y);
    add(hitbox);

    if (game.children.whereType<CollisionBlock>().isNotEmpty) {
      print("CollisionBlocks found: ${game.children.whereType<CollisionBlock>().length}");
    }

    return super.onLoad();
  }


  @override
  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  @override
  void update(double dt) {
    super.update(dt);
    // Verwende center (lokale Koordinaten) statt absolutePosition
    rayOriginPoint = center;

    results.clear();

    game.collisionDetection.raycastAll(
      startAngle: -90,
      rayOriginPoint,
      numberOfRays: numberOfRays,
      rays: rays,
      sweepAngle: 180,
      out: results,
      ignoreHitboxes: [hitbox]
    );

    if (!gotHit) {
      _updateEnemystate();
      _updateEnemyMovement(dt);
    }
  }

  @override
  void render(Canvas canvas) async {
    super.render(canvas);
    renderResult(canvas, rayOriginPoint, results, paint);
  }

  //render the RaycastsList
  void renderResult(Canvas canvas,
      Vector2 origin,
      List<RaycastResult<ShapeHitbox>> results,
      Paint paint) {
    for(final result in results){
      if(!result.isActive || result.intersectionPoint == null){
        continue;
      }


      // Beide Punkte sind jetzt im gleichen Koordinatensystem
      canvas.drawLine(
          origin.toOffset() - absolutePosition.toOffset() + hitbox.center.toOffset(),
          result.intersectionPoint!.toOffset() - absolutePosition.toOffset() + hitbox.center.toOffset(),
          Paint()..color = Colors.red..strokeWidth = 1.0
      );
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the player checks if the hitbox that it is colliding with is a Collectable or saw, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Saw && !debugImmortalMode) _respawn();

    checkCollision(other);

    super.onCollision(intersectionPoints, other);
  }


  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    verticalMovement = 0; //debug fly purposes only
    //movement keys
    final isLeftKeyPressed =
    keysPressed.contains(LogicalKeyboardKey.keyJ);
    final isRightKeyPressed =
    keysPressed.contains(LogicalKeyboardKey.keyL);
    //debug key bindings

    if(keysPressed.contains(LogicalKeyboardKey.keyF)) position = game.player.position.clone();
    if(keysPressed.contains(LogicalKeyboardKey.keyK)) print(results);
    if(keysPressed.contains(LogicalKeyboardKey.keyG)) debugFlyMode = !debugFlyMode;


    //ternary statement if leftkey pressed then add -1 to horizontal movement if not add 0 = not moving
    if (isLeftKeyPressed) horizontalMovement = -1;
    if (isRightKeyPressed) horizontalMovement = 1;

    //if the key is pressed than the player jumps in _updatePlayerMovement
    if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
      if (debugFlyMode) {
        verticalMovement = -1; //when in debug mode move the player upwards
      } else {
        hasJumped = true; //else jump
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }

//load all animations from asset files
  void _loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning -> needs to be cleaned up only quick and dirty fix
    e_idleAnimation = _spriteAnimation(
        pathPlayer, 'Idle ', 11, true, texture32file, textureSize32);
    e_runningAnimation = _spriteAnimation(
        pathPlayer, 'Run ', 12, true, texture32file, textureSize32);
    e_fallingAnimation = _spriteAnimation(
        pathPlayer, 'Fall ', 1, true, texture32file, textureSize32);
    e_jumpingAnimation = _spriteAnimation(
        pathPlayer, 'Jump ', 1, true, texture32file, textureSize32);
    e_hitAnimation = _spriteAnimation(
        pathPlayer, 'Hit ', 7, false, texture32file, textureSize32);
    e_appearAnimation = _spriteAnimation(
        pathRespawn, 'Appearing ', 7, false, texture96file, textureSize96);
    e_disappearAnimation = _spriteAnimation(
        pathRespawn, 'Disappearing ', 7, false, texture96file, textureSize96);


    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      EnemyState.idle: e_idleAnimation,
      EnemyState.running: e_runningAnimation,
      EnemyState.falling: e_fallingAnimation,
      EnemyState.jumping: e_jumpingAnimation,
      EnemyState.hit: e_hitAnimation,
      EnemyState.appearing: e_appearAnimation,
      EnemyState.disappearing: e_disappearAnimation,

    };

    //set current animation
    current = EnemyState.idle;
  }


  //Body Expression are concise ways of defining methods of function e.g.    int add(int a, int b) => a + b;
  //loop gets passed in to say if animation should be looped or not, e.g. hit should only be played once -> loop = false
  SpriteAnimation _spriteAnimation(String path, String state, int amount,
      bool loop, String fileName, double textureSize) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('$path$state$fileName'),
        SpriteAnimationData.sequenced(
          //11 image in the Idle.png
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(textureSize),
          loop: loop,
        ),
      );

  //only handles x movement for player
  void _updateEnemyMovement(double dt) {
    //if hasJumped is true and isOnGround is true the player can jump;
    if (hasJumped) if (isOnGround) {
      enemyJump();
    } else {
      hasJumped = false;
    }


    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *= 0.81 * (dt +
        1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
    position.x += velocity.x * dt;

    if (!debugFlyMode) velocity.y += _gravity;
    else {
      velocity.y += verticalMovement * moveSpeed * (dt + 1);
      velocity.y *= 0.9;
    }

    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  //handles animations and states
  void _updateEnemystate() {
    EnemyState enemyState = EnemyState.idle;
    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    if (velocity.x < -3 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 3 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 3 || velocity.x < -3) {
      enemyState = EnemyState.running;
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 0) enemyState = EnemyState.falling;

    if (velocity.y < 0) enemyState = EnemyState.jumping;

    //here the animation ist set after checking all of the conditions above
    current = enemyState;
  }

  void enemyJump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

  void _respawn() {
    gotHit = true;
    current = EnemyState.hit;
    velocity = Vector2.zero();
    //not time to fix animations needs to be done
    Future.delayed(Duration(milliseconds: 250), () {
      scale.x =
      0.33; //flip the player to the right side and a third of the size because the animation is triple of the size
      scale.y = 0.33;
      current = EnemyState.disappearing;
      Future.delayed(Duration(milliseconds: 150), () {
        Future.delayed(Duration(milliseconds: 450), () {
          position = startingPosition;

          position = startingPosition;

          current = EnemyState.appearing;
          Future.delayed(Duration(milliseconds: 350), () {
            scale.x = 1;
            scale.y = 1;
            _updateEnemystate();
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
