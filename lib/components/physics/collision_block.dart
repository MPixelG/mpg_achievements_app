import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_level.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import 'package:mpg_achievements_app/components/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//A positionComponent can have an x, y , width and height
class CollisionBlock extends PositionComponent with CollisionCallbacks, HasGameReference<PixelAdventure> {
  //position and size is given and passed in to the PositionComponent with super
  bool isPlatform;
  bool isLadder;
  bool hasCollisionUp;
  bool hasCollisionDown;
  bool hasHorizontalCollision;
  bool climbable;

  GameWorld? level;
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
    if (level != null && level is IsometricWorld) {
      hitbox = IsometricHitbox(size / 16 - Vector2.all(0.1), level!, Vector2.all(0.1));
    } else {
      hitbox = RectangleHitbox(position: Vector2(0, 0), size: size);
    }
    add(hitbox);
  }



  Vector2 get gridPos =>
      worldToTileIsometric(position);

  set gridPos(Vector2 newGridPos) {
    position = toWorldPos(newGridPos);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX = (worldPos.x / (game.tilesizeOrtho.x / 2) + worldPos.y / (game.tilesizeOrtho.y / 2)) / 2;
    final tileY = (worldPos.y / (game.tilesizeOrtho.y / 2) - worldPos.x / (game.tilesizeOrtho.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  Vector2 toWorldPos(Vector2 gridPos) {
    return Vector2(
      (gridPos.x - gridPos.y) * (game.tilesizeOrtho.x / 2),
      (gridPos.x + gridPos.y) * (game.tilesizeOrtho.y / 2),
    );
  }

}
