import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/physics/movement.dart';

mixin IsometricMovement on BasicMovement {
  double zMovement =
  0; // Directional input (up/down) for z axis for isometric view
  final double _isometricJumpForce = 150;
  final double _isometricGravity = 50;
  double zVelocity = 0.0;
  double zPosition = 0.0;
  final double _friction = 0.75;
  final double _terminalVelocity = 150;
  //character's height off the ground plan


  @override
  void update(double dt) {
    if (updateMovement) {
      _updateMovement(dt);
    }
  }

  void _updateMovement(double dt) {
    _performIsometricMovement(dt);
    if (gravityEnabled) {
      _performIsometricGravity(dt);
    }
    gridPos += velocity * dt;
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
   /* if(DateTime.now().millisecondsSinceEpoch % 100 < 10){
      print('currentGround:$currentZGround');
      print('zPosition:$zPosition');
      print('zV:$zVelocity');
      print('zM:$zMovement');}*/
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

@override
  void jump() {
    zVelocity = -_isometricJumpForce;
    isOnGround = false;
    hasJumped = false;
  }

  void _performIsometricMovement(double dt) {
    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *= _friction * (dt + 1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
    velocity.y += verticalMovement * moveSpeed;
    velocity.y *= _friction * (dt + 1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction

  }
  double getzPosition() => zPosition;
}