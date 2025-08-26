import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

//A positionComponent can have an x, y , width and height
class CollisionBlock extends PositionComponent with CollisionCallbacks {
  //position and size is given and passed in to the PositionComponent with super
  bool isPlatform;
  bool isLadder;
  bool hasCollisionUp;
  bool hasCollisionDown;
  bool hasHorizontalCollision;
  bool climbable;
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
    this.hasCollisionUp = true,
    this.hasCollisionDown = true,
    this.hasHorizontalCollision = true,
    this.climbable = false,
    this.isLadder = false,
  });

  RectangleHitbox hitbox = RectangleHitbox();
  @override
  FutureOr<void> onLoad() {
    hitbox = RectangleHitbox(position: Vector2(0, 0), size: size);
    add(hitbox);
  }

}
