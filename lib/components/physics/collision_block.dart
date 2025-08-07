import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_level.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:mpg_achievements_app/components/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';

//A positionComponent can have an x, y , width and height
class CollisionBlock extends PositionComponent with CollisionCallbacks {
  //position and size is given and passed in to the PositionComponent with super
  bool isPlatform;
  bool isLadder;
  bool hasCollisionUp;
  bool hasCollisionDown;
  bool hasHorizontalCollision;
  bool climbable;

  Level? level;
  CollisionBlock({
    super.position,
    super.size,
    this.isPlatform = false,
    this.hasCollisionUp = true,
    this.hasCollisionDown = true,
    this.hasHorizontalCollision = true,
    this.climbable = false,
    this.isLadder = false,
    this.level
  });

  ShapeHitbox hitbox = RectangleHitbox();
  @override
  FutureOr<void> onLoad() {
    if (level != null && level is IsometricLevel) {
      final transformedPosition = _orthogonalToIsometricGrid(position);

      final finalPosition = transformedPosition + Vector2(level!.level.width / 2, 0) + level!.tileSize;

      position = finalPosition;

      final transformedSize = size / 16;
      hitbox = IsometricHitbox(transformedSize, level!, anchor: Anchor.topCenter);
    } else {
      // Regular orthogonal hitbox
      hitbox = RectangleHitbox(position: Vector2(0, 0), size: size);
    }
    add(hitbox);
  }

  // Use the same transformation as IsometricTileGrid
  Vector2 _orthogonalToIsometricGrid(Vector2 orthoPos) {
    return Vector2(
        ((orthoPos.x - orthoPos.y) * 1.0),
        (orthoPos.x + orthoPos.y) * 0.5 + 1
    );
  }
}
