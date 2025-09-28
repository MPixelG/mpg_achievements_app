import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';

import '../../mpg_pixel_adventure.dart';
import '../entity/gameCharacter.dart';
import 'collisions.dart';

mixin BasicMovement on GameCharacter, HasGameReference<PixelAdventure> {
  //constants for configuring basic movement
  final double _gravity = 20;

  final double _jumpForce = 12;

  final double _terminalVelocity = 150;
  final double _friction = 0.75;

  double moveSpeed = 3; // Speed multiplier

  double horizontalMovement = 0; // Directional input (left/right)
  double verticalMovement = 0; // Directional input (up/down)
  Vector2 velocity = Vector2.zero();
  //character's height off the ground plane



  bool debugFlyMode = false;
  bool hasJumped = false;
  bool isOnGround = false;
  bool gravityEnabled = true;
  bool isShifting = false;
  bool updateMovement = true;

  late ViewSide viewSide;


  void update(double dt) {
    if (updateMovement) {
      _updateMovement(dt);
    }
  }

  void setMovementType(ViewSide newType) => viewSide = newType;

  void setGravityEnabled(bool val) => gravityEnabled = val;

  bool get isClimbing;



  // Updates movement logic based on input and physics
  void _updateMovement(double dt) {
    if (hasJumped) {
        hasJumped = false;
    }
    // Horizontal movement and friction
    if (viewSide case ViewSide.side) {
      velocity.x += horizontalMovement * moveSpeed;
      velocity.x *=
          _friction *
          (dt +
              1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
      if (gravityEnabled) {
        _performGravity(dt);
      }
    } else if (viewSide case ViewSide.topDown) {
      throw UnimplementedError();
    }

    // Apply final velocity to position

    gridPos += velocity * dt;
  }

  // Applies gravity and falling mechanics
  void _performGravity(double dt) {
    if (!debugFlyMode && !isClimbing) {
      if (isClimbing) {
        velocity.y += _gravity * dt * 0.02; // Fall down
      } else {
        velocity.y += _gravity * dt;
      }
    } else {
      velocity.y += verticalMovement * moveSpeed * (dt * 1000);
      velocity.y *= pow(0.01, dt); // Simulated drag
    }
    //limit fall speed to terminalVelocity
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
  }




  void jump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }







}
