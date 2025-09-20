import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/entity/gameCharacter.dart';
import 'package:mpg_achievements_app/components/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'collision_block.dart';
import 'movement.dart';


enum ViewSide { topDown, side, isometric }

/// Mixin for adding collision detection behavior to a component.
/// Requires implementing methods to provide hitbox, position, velocity, etc
mixin HasCollisions on GameCharacter, CollisionCallbacks, HasGameReference<PixelAdventure>, BasicMovement {
  ShapeHitbox getHitbox();

  Vector2 getScale();

  Vector2 getVelocity();

  Vector2 getPosition();

  void setClimbing(bool val);

  void setDebugNoClipMode(bool val) => _debugNoClipMode = val;

  bool get isTryingToGetDownLadder;

  bool _debugNoClipMode = false;

  late ShapeHitbox hitbox;
  @override
  FutureOr<void> onLoad() {
    if(viewSide == ViewSide.isometric) {
      hitbox = IsometricHitbox(
          Vector2.all(1),
          game.gameWorld,
          Vector2.zero(),
      );
      hitbox.position = Vector2(0, 16);
    } else {
      hitbox = RectangleHitbox(
        size: Vector2(20, 26),
        position: Vector2(6, 4)
      );
    }

    add(hitbox);
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(viewSide != ViewSide.side && other is CollisionBlock && !_debugNoClipMode) {
      velocity = Vector2.zero();
      gridPos = lastSafePosition;
      return;
    }

    if (other is CollisionBlock && !_debugNoClipMode) {
      checkCollision(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  // Called when the collision with another object ends
  @override
  void onCollisionEnd(PositionComponent other) {
    if(viewSide == ViewSide.side){

      Future.delayed((Duration(milliseconds: 100)), () { //reset isOnGround after a short delay so that its a bit more forgiving when jumping from edges (lol)
        if (!activeCollisions.any((element) => element is CollisionBlock)) {
          isOnGround = false;
        }
      });

      if (other is CollisionBlock && other.climbable) {
        setClimbing(false);
      }
    }

    super.onCollisionEnd(other);
  }

  //main collision physics
  void checkCollision(PositionComponent other) {
    if (other is! CollisionBlock) {
      return; //physics only work on the collision blocks (including the platforms)
    }

    ShapeHitbox hitbox = getHitbox();
    Vector2 scale = getScale();
    Vector2 velocity = getVelocity();

    Vector2 position = getPosition();

    Vector2 posDiff =
        hitbox.absolutePosition -
            other
                .absolutePosition; //the difference of the position of the player hitbox and the obstacle hitbox. this allows you to see how much they are overlapping on the different axis.

    //if the player faces in the other direction, we want to measure the distances from the other side of the hitbox. so we just add the width of it to the value.
    if (scale.x < 0) {
      posDiff.x -= hitbox.width;
    }

    //get all the distances it would take to transport the player to this side of the platform
    final double distanceUp = posDiff.y + hitbox.height;
    final double distanceLeft = posDiff.x + hitbox.width;
    final double distanceRight = other.width - posDiff.x;
    final double distanceDown = other.height - posDiff.y;

    final double smallestDistance = min(
      min(distanceUp, distanceDown),
      min(distanceRight, distanceLeft),
    ); //get the smallest distance

    // Resolve the collision in the direction of smallest overlap
    if (smallestDistance == distanceUp &&
        velocity.y > 0 &&
        !(!other.hasCollisionDown && distanceUp > 8) &&
        other.hasCollisionUp &&
        !(other.isLadder && isTryingToGetDownLadder)) {
      position.y -= distanceUp;

      isOnGround = true;
      velocity.y = 0;
    } //make sure you're falling (for platforms), then update the position, set the player on the ground and reset the velocity. if the block is a platform, then only move the player if the distance isn't too high, otherwise if half of the player falls through  a platform, he gets teleported up
    else if (smallestDistance == distanceDown && other.hasCollisionDown) {
      position.y += distanceDown;
      velocity.y = 0;
    } //make sure the block isn't a platform, so that you can go through it from the bottom
    else if (smallestDistance == distanceLeft && other.hasHorizontalCollision) {
      position.x -= distanceLeft;
      velocity.x = 0;
    } //make sure the block isn't a platform, so that you can go through it horizontally
    else if (smallestDistance == distanceRight && other.hasHorizontalCollision) {
      position.x += distanceRight;
      velocity.x = 0;
    }
    if (other.climbable && distanceUp > 5) setClimbing(true);
  }

  //TODO FIX
  void checkCollisionIsometric(CollisionBlock other){
    hitbox.aabb.intersectsWithAabb2(other.hitbox.aabb);

    Vector2 gridPos = game.gameWorld.toGridPos(position);

    Vector2 otherGridPos = game.gameWorld.toGridPos(other.position);

    Vector2 posDiff = gridPos - otherGridPos;
    print("\nposDiff: $posDiff");
    print("gridPos: $gridPos");
    print("other grid pos: $otherGridPos");

    final double distanceUp = posDiff.y + hitbox.height / 32;
    final double distanceLeft = posDiff.x + hitbox.width / 32;
    final double distanceRight = (other.width / 32) - posDiff.x;
    final double distanceDown = (other.height / 32) - posDiff.y;

    double smallestDistance = min(min(distanceUp, distanceLeft), min(distanceRight, distanceDown));

    Vector2 newGridPos = gridPos;
    if(smallestDistance == distanceUp){
      print("up");
      newGridPos.x -= 0.1;
      velocity.x = 0;
    }if(smallestDistance == distanceLeft){
      print("left");
      newGridPos.y += 0.1;
      velocity.y = 0;
    }if(smallestDistance == distanceRight){
      print("right");
      newGridPos.x += 0.1;
      velocity.x = 0;
    }if(smallestDistance == distanceDown){
      print("down");
      newGridPos.y -= 0.1;
      velocity.y = 0;
    }

    gridPos = newGridPos;
  }

  Vector2 lastSafePosition = Vector2.zero();
  @override
  void update(double dt) {
    if (viewSide != ViewSide.isometric || _debugNoClipMode) return super.update(dt);

    if(!game.gameWorld.checkCollisionAt(gridPos.clone()..floor())){
      lastSafePosition = gridPos;
    } else {
    }
    super.update(dt);
  }

  bool isHitboxInside(Hitbox? hitboxA, Hitbox? hitboxB) {
    if(hitboxB == null || hitboxA == null) return false;
    return hitboxB.aabb.toRect().translate(0.8, 0.8).overlaps(hitboxA.aabb.toRect());
  }
}