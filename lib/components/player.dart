import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'saw.dart';

enum PlayerState { idle, running, jumping, falling, hit, appearing, disappearing }

class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  String character;
  String pathRespawn = 'Main Characters/';
  late String pathPlayer = 'Main Characters/$character/';

  double textureSize32 = 32;
  double textureSize96 = 96;
  String texture32file = ' (32x32).png';
  String texture96file = ' (96x96).png';

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearAnimation;
  late final SpriteAnimation disappearAnimation;
  final double stepTime = 0.05;

  final double _gravity = 15;
  final double _jumpForce = 320;
  final double _terminalVelocity = 300;

  bool debugFlyMode = false;
  bool debugNoClipMode = false;

  bool hasJumped = false;
  bool gotHit = false;

  double moveSpeed = 120;
  double horizontalMovement = 0;
  double verticalMovement = 0;

  Vector2 velocity = Vector2.zero();
  Vector2 startingPosition = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  late RectangleHitbox hitbox;
  bool isOnGround = false;

  Player({required this.character, super.position});

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    startingPosition = Vector2(position.x, position.y);
    debugMode = true;

    hitbox = RectangleHitbox(
      position: Vector2(4, 6),
      size: Vector2(24, 26),
    );
    add(hitbox);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotHit) {
      _updatePlayerstate();
      _updatePlayerMovement(dt);
    }
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

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      hasJumped = true;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!debugNoClipMode) {
      if (other is Collectable) other.collidedWithPlayer();
      if (other is Saw) _respawn();
    }
    super.onCollision(intersectionPoints, other);
  }


  void collideWithBlock(Set<Vector2> intersectionPoints, ShapeHitbox other){
    Vector2 leftPoint = intersectionPoints.first.clone();
    Vector2 rightPoint = intersectionPoints.elementAt(1).clone();

    if(leftPoint.x == rightPoint.x) collideHorizontally(leftPoint, rightPoint, other);
    if(leftPoint.y == rightPoint.y) collideVertically(leftPoint, rightPoint, other);






  }

  void collideVertically(Vector2 firstIntersection, Vector2 secondIntersection, ShapeHitbox other){
    Vector2 intersectionPoint = getNearestPointToEdge(firstIntersection, firstIntersection, Vector2(other.absoluteCenter.x, other.absolutePosition.y));

    Vector2 relativePos = other.absolutePosition-hitbox.absolutePosition-hitbox.size; //the difference between the height of the player and the height of the plattform
    if(intersectionPoint.y == other.absolutePosition.y && velocity.y > 0) { //when the intersection is on the top of the floor and your falling
      position.y += relativePos.y;
      isOnGround = true;
      velocity.y = 0; //reset velocity
    } else if (velocity.y < 0 && !(other.parent as CollisionBlock).isPlatform) { //when going up you just hit your head on a ceiling
      position.y += (other.absolutePosition - hitbox.absolutePosition + other.size).y;
      velocity.y = 0; //reset velocity
    }
  }

  void collideHorizontally(Vector2 firstIntersection, Vector2 secondIntersection, ShapeHitbox other){
    Vector2 intersectionPoint = getNearestPointToEdge(firstIntersection, firstIntersection, other.absoluteCenter);
    Vector2 relativePos = other.absolutePosition-hitbox.absolutePosition-hitbox.size;

    if(-relativePos.x > width / 2){
      position.x += relativePos.x + width;
      print("left");
    } else {
      position.x += relativePos.x;
      print("right");
    }

  }

  Vector2 getNearestPointToEdge(Vector2 first, Vector2 second, Vector2 platformCentre){ //returns the point thats the closest to the centre of the plattform
      if(first.distanceTo(platformCentre) < second.distanceTo(platformCentre))
        return first;
      else return second;
  }



  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation(pathPlayer, 'Idle', 11, true, texture32file, textureSize32);
    runningAnimation = _spriteAnimation(pathPlayer, 'Run', 12, true, texture32file, textureSize32);
    fallingAnimation = _spriteAnimation(pathPlayer, 'Fall', 1, true, texture32file, textureSize32);
    jumpingAnimation = _spriteAnimation(pathPlayer, 'Jump', 1, true, texture32file, textureSize32);
    hitAnimation = _spriteAnimation(pathPlayer, 'Hit', 7, false, texture32file, textureSize32);
    appearAnimation = _spriteAnimation(pathRespawn, 'Appearing', 7, false, texture96file, textureSize96);
    disappearAnimation = _spriteAnimation(pathRespawn, 'Disappearing', 7, false, texture96file, textureSize96);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearAnimation,
      PlayerState.disappearing: disappearAnimation,
    };
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String path, String state, int amount,
          bool loop, String fileName, double textureSize) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('$path$state$fileName'),
        SpriteAnimationData.sequenced(
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(textureSize),
          loop: loop,
        ),
      );

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _jump();

    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
    _checkHorizontalCollisions();

    position.y += velocity.y * dt;
    _checkVerticalCollisions();
  }

  void _updatePlayerstate() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x != 0) {
      playerState = PlayerState.running;
    }

    if (velocity.y > 0 && !isOnGround) {
      playerState = PlayerState.falling;
    }

    if (velocity.y < 0 && !isOnGround) {
      playerState = PlayerState.jumping;
    }

    current = playerState;
  }

  void _jump() {
    velocity.y = -_jumpForce;
    isOnGround = false;
    hasJumped = false;
  }

  void _respawn() async {
    // Your respawn logic...
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          final playerRect = hitbox.toAbsoluteRect();
          final blockRect = block.toAbsoluteRect();
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x -= (playerRect.right - blockRect.left);
          } else if (velocity.x < 0) {
            velocity.x = 0;
            position.x += (blockRect.right - playerRect.left);
          }
        }
      }
    }
  }

  void _checkVerticalCollisions() {
    isOnGround = false;
    for (final block in collisionBlocks) {
      if (checkCollision(this, block)) {
        final playerRect = hitbox.toAbsoluteRect();
        final blockRect = block.toAbsoluteRect();

        if (velocity.y > 0) { // Player is falling
          if (block.isPlatform) {
            // Land on platform only if coming from above.
            if (playerRect.top < blockRect.top) {
              velocity.y = 0;
              position.y -= (playerRect.bottom - blockRect.top);
              isOnGround = true;
              break; // Found ground, stop checking.
            }
          } else { // It's a solid block, always collide.
            velocity.y = 0;
            position.y -= (playerRect.bottom - blockRect.top);
            isOnGround = true;
            break; // Found ground, stop checking.
          }
        }
        
        if (velocity.y < 0) { // Player is jumping
          // Can only hit the ceiling of solid blocks.
          if (!block.isPlatform) {
            velocity.y = 0;
            position.y += (blockRect.bottom - playerRect.top);
          }
        }
      }
    }
  }
}