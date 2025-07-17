import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/player.dart';

import '../collision_block.dart';

mixin HasCollisions on Component, CollisionCallbacks {

  ShapeHitbox getHitbox();
  Vector2 getScale();
  Vector2 getVelocity();
  Vector2 getPosition();



  void setPos(Vector2 newPos);
  void setIsOnGround(bool val);
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    checkCollision(other);
    super.onCollision(intersectionPoints, other);
  }

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

    if (smallestDistance == distanceUp && velocity.y > 0 && !(other.isPlatform && distanceUp > 6)) {position.y -= distanceUp; setIsOnGround(true); velocity.y = 0;} //make sure youre falling (for plattforms), then update the position, set the player on the ground and reset the velocity. if the block is a platform, then only move the player if the distance isnt too high, otherwise if half of the player falls through  a plattform, he gets teleported up
    if (smallestDistance == distanceDown && !other.isPlatform) {position.y += distanceDown; velocity.y = 0;} //make sure the block isnt a plattform, so that you can go through it from the bottom
    if (smallestDistance == distanceLeft && !other.isPlatform) {position.x -= distanceLeft; velocity.x = 0;} //make sure the block isnt a plattform, so that you can go through it horizontally
    if (smallestDistance == distanceRight && !other.isPlatform) {position.x += distanceRight; velocity.x = 0;}

    setPos(position);
  }
}