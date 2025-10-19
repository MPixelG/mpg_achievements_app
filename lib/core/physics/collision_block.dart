import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//A positionComponent can have an x, y , width and height, zPosition and zHeight
class CollisionBlock extends PositionComponent
    with CollisionCallbacks, HasGameReference<PixelAdventure> {
  //position and size is given and passed in to the PositionComponent with super
  int? zPosition;
  int? zHeight;

  bool? isIsometric;
  CollisionBlock({
    super.position,
    super.size,
    this.zPosition = 0,
    this.zHeight = 0,
  });

  ShapeHitbox hitbox = RectangleHitbox();
  @override
  FutureOr<void> onLoad() {
    if (isIsometric != null && isIsometric!) {
      hitbox = IsometricHitbox(size / tilesize.z - Vector2.all(0.1), Vector3.all(0.1));
    } else {
      hitbox = RectangleHitbox(position: Vector2(0, 0), size: size);
    }
    add(hitbox);
  }

  Vector2 get gridPos => worldToTileIsometric(position);

  set gridPos(Vector2 newGridPos) {
    position = toWorldPos(newGridPos);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX =
        (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.y / 2)) / 2;
    final tileY =
        (worldPos.y / (tilesize.y / 2) - worldPos.x / (tilesize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  Vector2 toWorldPos(Vector2 gridPos) {
    return Vector2(
      (gridPos.x - gridPos.y) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.y / 2),
    );
  }
}
