import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'collision_block.dart';
import '../level.dart';

mixin HasCollisions on Component, CollisionCallbacks {

  ShapeHitbox getHitbox();
  Vector2 getScale();
  Vector2 getVelocity();
  Vector2 getPosition();

  void setClimbing(bool val);

  bool _debugNoClipMode = false;


  void setPos(Vector2 newPos);
  void setIsOnGround(bool val);
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(other is CollisionBlock && !_debugNoClipMode) {
      checkCollision(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if(other is CollisionBlock && other.climbable) {
      setClimbing(false);
    }
    super.onCollisionEnd(other);
  }


  void setDebugNoCipMode(bool val) => _debugNoClipMode = val;

  void checkCollision(PositionComponent other){
    if (other is! CollisionBlock) return; //physics only work on the collision blocks (including the platforms)

    ShapeHitbox hitbox = getHitbox();
    Vector2 scale = getScale();
    Vector2 velocity = getVelocity();

    Vector2 position = getPosition();

    Vector2 posDiff = hitbox.absolutePosition - other.absolutePosition; //the difference of the position of the player hitbox and the obstacle hitbox. this allows you to see how much they are overlapping on the different axis.

    //if the player faces in the other direction, we want to measure the distances from the other side of the hitbox. so we just add the width of it to the value.
    if(scale.x < 0) {
      posDiff.x -= hitbox.width;
    }

    //get all the distances it would take to transport the player to this side of the plattform
    final double distanceUp = posDiff.y + hitbox.height;
    final double distanceLeft = posDiff.x + hitbox.width;
    final double distanceRight = other.width - posDiff.x;
    final double distanceDown = other.height - posDiff.y;

    final double smallestDistance = min(min(distanceUp, distanceDown), min(distanceRight, distanceLeft)); //get the smallest distance

    if (smallestDistance == distanceUp && velocity.y > 0 && !(!other.hasCollisionDown && distanceUp > 8) && other.hasCollisionUp) {position.y -= distanceUp; setIsOnGround(true); velocity.y = 0;} //make sure youre falling (for plattforms), then update the position, set the player on the ground and reset the velocity. if the block is a platform, then only move the player if the distance isnt too high, otherwise if half of the player falls through  a plattform, he gets teleported up
    if (smallestDistance == distanceDown && other.hasCollisionDown) {position.y += distanceDown; velocity.y = 0;} //make sure the block isnt a plattform, so that you can go through it from the bottom
    if (smallestDistance == distanceLeft && other.hasHorizontalCollision) {position.x -= distanceLeft; velocity.x = 0;} //make sure the block isnt a plattform, so that you can go through it horizontally
    if (smallestDistance == distanceRight && other.hasHorizontalCollision) {position.x += distanceRight; velocity.x = 0;}

    if(other.climbable) setClimbing(true);

    setPos(position);
  }
}

enum ViewSide {
  topDown, side
}


mixin BasicMovement on PositionComponent {

  final double _gravity = 15.0;
  final double _jumpForce = 320;
  final double _terminalVelocity = 300;
  final double _friction = 0.81;


  double moveSpeed = 35;

  double horizontalMovement = 0;

  double verticalMovement = 0;
  bool debugFlyMode = false;

  Vector2 velocity = Vector2.zero();

  bool hasJumped = false;

  bool isOnGround = false;

  bool gravityEnabled = true;


  ViewSide viewSide = ViewSide.side;

  @override
  void update(double dt) {
    _updateMovement(dt);
  }

  void setMovementType(ViewSide newType) => viewSide = newType;

  void setGravityEnabled(bool val) => gravityEnabled = val;

  bool isClimbing();

  void _updateMovement(double dt) {
    if (hasJumped) if (isOnGround) jump(); else hasJumped = false;

    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *= _friction * (dt+1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
    position.x += velocity.x * dt;

    if(viewSide == ViewSide.side && gravityEnabled) _performGravity(dt);
    else _performVerticalMovement(dt);

    position.y += velocity.y * dt;
  }

  void _performGravity(double dt){
    if(!debugFlyMode && !isClimbing()) velocity.y += _gravity;
    else {
      velocity.y += verticalMovement * moveSpeed * (dt + 1);
      velocity.y *= 0.9;
    }
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
  }

  void _performVerticalMovement(double dt){
    velocity.y += verticalMovement * moveSpeed * (dt + 1);
    velocity.y *= _friction * (dt+1);
  }


  void jump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

}

mixin KeyboardControllableMovement on PositionComponent, BasicMovement, KeyboardHandler{



  bool active = true;
  Vector2 mouseCoords = Vector2.zero();
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if(!active) return super.onKeyEvent(event, keysPressed);

    horizontalMovement = 0;
    verticalMovement = 0;

    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
            keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
            keysPressed.contains(LogicalKeyboardKey.keyD);

    //ternary statement if left key pressed then add -1 to horizontal movement if not add 0 = not moving
    if(isLeftKeyPressed) horizontalMovement --;
    if(isRightKeyPressed) horizontalMovement ++;


    if(viewSide == ViewSide.side) {
      if (keysPressed.contains(LogicalKeyboardKey.controlLeft))
        debugFlyMode = !debugFlyMode; // press left ctrl to toggle fly mode
      //if the key is pressed than the player jumps in _updatePlayerMovement
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        if (debugFlyMode || isClimbing()) {
          verticalMovement = -1; //when in debug mode move the player upwards
        } else {
          hasJumped = true; //else jump
        }
      }

      if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) &&
          (debugFlyMode || isClimbing())) { //when in fly mode and shift is pressed, the player gets moved down
        verticalMovement = 1;
      }
    } else if(viewSide == ViewSide.topDown){

      final isUpKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyW) ||
              keysPressed.contains(LogicalKeyboardKey.arrowUp);
      final isDownKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyS) ||
              keysPressed.contains(LogicalKeyboardKey.arrowDown);

      if(isUpKeyPressed) verticalMovement --;
      if(isDownKeyPressed) verticalMovement ++;

    }




    if (keysPressed.contains(LogicalKeyboardKey.keyT)) position = mouseCoords; //press T to teleport the player to the mouse
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {debugMode = !debugMode; (parent as Level).setDebugMode(debugMode);} //press Y to toggle debug mode (visibility of hitboxes and more)

    return super.onKeyEvent(event, keysPressed);
  }

  bool isClimbing();

  bool setControllable(bool val) => active = val;

}