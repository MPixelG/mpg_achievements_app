import 'dart:math' as math;

import 'package:flame/components.dart';

import 'new_animated_character.dart';

mixin HasMovementAnimations on AnimatedCharacter{
  
  static const List<double> possibleIsoDirections = [
    0, 45, 90, 135, 180, 225, 270, 315
  ];
  double calculateIsoDirection(Vector3 velocity) {
    if (velocity.x == 0 && velocity.z == 0) {
      return possibleIsoDirections.first;
    }

    double angle = math.atan2(-velocity.z, -velocity.x) * 180 / math.pi;

    angle = (angle + 360) % 360;

    angle = (angle - 45) % 360;

    double nearest = possibleIsoDirections.first;
    double minDiff = 360;

    for (final d in possibleIsoDirections) {
      double diff = (angle - d).abs();
      if (diff > 180) diff = 360 - diff;

      if (diff < minDiff) {
        minDiff = diff;
        nearest = d;
      }
    }

    return nearest;
  }


  bool
  get isInHitFrames; //if the player is currently being hit, we dont want to overwrite the animation
  bool
  get isInRespawnFrames; //if the player is currently respawning, we dont want to overwrite the animation
  

  //todo renaming necessary
  void updatePlayerstate() {
    if (isInRespawnFrames || isInHitFrames || textureBatch == null) {
      return; //if we are in respawn or hit frames we dont want to change the animation
    }
    
    String nextAnimation = "idle";

    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    //Check if moving
    if (velocity.length > 4) {
      direction = calculateIsoDirection(velocity);
      nextAnimation = "walk";
      animationTicker?.timeMultiplier = velocity.length * 0.1;
    } else animationTicker?.timeMultiplier = 1;


    // update state to falling if velocity is greater than 0
    // if (velocity.y > 4) nextAnimation = "jumping";

    // if (velocity.y < -4) nextAnimation = "falling";

    current = nextAnimation;
  }
}
