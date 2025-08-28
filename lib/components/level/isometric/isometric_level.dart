
import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../physics/movement_collisions.dart';
import '../level.dart';

class IsometricLevel extends Level{
  IsometricLevel({required super.levelName, required super.player});

  @override
  Vector2 toGridPos(Vector2 worldPos) {
    // Remove the offset and width/2 translation for cleaner conversion
    Vector2 adjustedPos = worldPos - Vector2(level.position.x, level.position.y);
    return worldToTileIsometric(adjustedPos - Vector2(level.position.x + (level.width / 2), level.position.y)) + Vector2(1, 1);
  }

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    // Standard isometric world-to-tile conversion
    final tileX = (worldPos.x / (tileSize.x / 2) + worldPos.y / (tileSize.y / 2)) / 2;
    final tileY = (worldPos.y / (tileSize.y / 2) - worldPos.x / (tileSize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }


  @override
  Vector2 toWorldPos(Vector2 gridPos) {
    // Standard isometric tile-to-world conversion
    return Vector2(
      (gridPos.x - gridPos.y) * (tileSize.x / 2),
      (gridPos.x + gridPos.y) * (tileSize.y / 2),
    );
  }

  @override
  FutureOr<void> onLoad() {
    player.viewSide = ViewSide.topDown;
    return super.onLoad();
  }

  @override
  bool checkCollisionAt(Vector2 point, Vector2 center, Vector2 size) {
    throw UnimplementedError();
  }

  @override
  RectangleHitbox createHitbox({Vector2? position, Vector2? size}) {
    return RectangleHitbox(position: position, size: size);
  }




}