import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/entity/player.dart';

import '../../mpg_pixel_adventure.dart';
import '../entity/gameCharacter.dart';
import 'collisions.dart';

mixin BasicMovement on GameCharacter, HasGameReference<PixelAdventure> {
  //constants for configuring basic movement
  final double _gravity = 20;
  final double _isometricGravity = 50;
  final double _jumpForce = 12;
  final double _isometricJumpForce = 150;
  final double _terminalVelocity = 150;
  final double _friction = 0.75;

  double moveSpeed = 3; // Speed multiplier

  double horizontalMovement = 0; // Directional input (left/right)
  double verticalMovement = 0; // Directional input (up/down)
  double zMovement =
      0; // Directional input (up/down) for z axis for isometric view
  Vector2 velocity = Vector2.zero();
  double zVelocity = 0.0;
  double zPosition = 0.0;
  //character's height off the ground plane



  bool debugFlyMode = false;
  bool hasJumped = false;
  bool isOnGround = false;
  bool gravityEnabled = true;
  bool isShifting = false;
  bool updateMovement = true;

  late ViewSide viewSide;

  @override
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
      if (isOnGround) {
        viewSide == ViewSide.isometric ? isometricJump() : jump();
      } else {
        hasJumped = false;
      }
    }
    // Horizontal movement and friction

    switch (viewSide) {
      case ViewSide.isometric:
        _performIsometricMovement(dt);
        if (gravityEnabled) {
         _performIsometricGravity(dt);
        }
        break;

      case ViewSide.side:
        velocity.x += horizontalMovement * moveSpeed;
        velocity.x *=
            _friction *
            (dt +
                1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
        if (gravityEnabled) {
          _performGravity(dt);
        }

      /*maybe not necessary if we don't have topdown at all
      case ViewSide.topDown:
        velocity.x += horizontalMovement * moveSpeed;
        velocity.y += verticalMovement * moveSpeed;
        velocity *= _friction * (dt + 1);*/
        break;
      case ViewSide.topDown:
        // TODO: Handle this case.
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

  void _performIsometricGravity(double dt) {
    //access the player's ground level
    final player = this as Player;
    final currentZGround = player.zGround;

    if (!debugFlyMode && !isClimbing) {
      if(!isOnGround || zVelocity < 0){

      zVelocity += _isometricGravity * dt;} //fall
      //limit falls speed
     zVelocity = zVelocity.clamp(-_isometricJumpForce, _terminalVelocity);
      // Apply Z velocity to Z position
      zPosition += zVelocity * dt;
      }
      //only print when counter is below 10
      if(DateTime.now().millisecondsSinceEpoch % 100 < 10){
      print('currentGround:$currentZGround');
      print('zPosition:$zPosition');
      print('zV:$zVelocity');
      print('zM:$zMovement');}
      // Only apply gravity if not on the ground
      if (zPosition >= currentZGround && zVelocity >= 0) {
        zPosition = currentZGround;
        zVelocity = 0;
        isOnGround = true;
        //print('Player landed at:$zPosition');
      } else {
        isOnGround = false;}

      if(debugFlyMode){
        zPosition += zMovement * moveSpeed * dt*10 ;
        zVelocity = 0;
        isOnGround =(zPosition >= currentZGround);
      }
    }


  void jump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

  //needs more work just basic
  void isometricJump() {
    zVelocity = -_isometricJumpForce;
    isOnGround = false;
    hasJumped = false;
  }

  //isometric movement logic
  void _performIsometricMovement(double dt) {
    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *=
        _friction *
        (dt +
            1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction

    velocity.y += verticalMovement  *  moveSpeed;
    velocity.y *=
        _friction *
        (dt +
            1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction

    }

  double getzPosition() => zPosition;

}
