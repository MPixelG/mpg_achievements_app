import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/movement.dart';

mixin IsometricMovement on BasicMovement, IsoPositionComponent {
  final double _isometricJumpForce = 190;
  final double _isometricGravity = 350;
  final double _terminalVelocity = 500;
  //character's height off the ground plan

  void updateIsometricMovement(double dt) {
    //velocity to x/y
_performIsometricMovement(dt);

    if (hasJumped) {
      _jump();
      hasJumped = false;
    }

    if (gravityEnabled) {
      _performIsometricGravity(dt);
    }
    }

  void _performIsometricGravity(double dt) {
    //access the player's ground level
    final player = this as Player;
    final currentZGround = player.zGround;

    if (!debugFlyMode && !isClimbing) {
      if (!isOnGround || velocity.z < 0) {
       velocity.z += _isometricGravity * dt;
      } //fall
      //limit falls speed
      velocity.z = velocity.z.clamp(-_isometricJumpForce, _terminalVelocity);
      // Apply Z velocity to Z position
      isoPosition.z += velocity.z * dt;
    }
    //only print when counter is below 10
    /* if(DateTime.now().millisecondsSinceEpoch % 100 < 10){
      print('currentGround:$currentZGround');
      print('zPosition:$zPosition');
      print('zV:$zVelocity');
      print('zM:$zMovement');}*/
    // Only apply gravity if not on the ground
    if ( isoPosition.z >= currentZGround && velocity.z > 0) {
      isoPosition.z = currentZGround;
      velocity.z = 0;
      isOnGround = true;
      //print('Player landed at:$zPosition');
    } else {
      isOnGround = false;
    }

    if (debugFlyMode) {
      isoPosition.z += zMovement * moveSpeed * dt * 10;
      velocity.z = 0;
      isOnGround = (isoPosition.z <= currentZGround);
    }
  }

  void _jump() {
    if(!isOnGround) return;
    velocity.z = -_isometricJumpForce;
    isOnGround = false;
    hasJumped = false;
  }

  void _performIsometricMovement(double dt) {
    //friction is handled in IsoComponent
    velocity.x += horizontalMovement * moveSpeed;
    velocity.y += verticalMovement * moveSpeed;


  }
  double getzPosition() => isoPosition.z;
}