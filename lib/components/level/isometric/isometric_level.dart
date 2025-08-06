
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/src/collisions/hitboxes/rectangle_hitbox.dart';
import 'package:mpg_achievements_app/components/physics/isometric_hitbox.dart';
import 'package:vector_math/vector_math.dart';

import '../../physics/collisions.dart';
import '../level.dart';

class IsometricLevel extends Level{
  IsometricLevel({required super.levelName, required super.player});

  @override
  Vector2 toGridPos(Vector2 pos) {
    return screenToTileIsometric(screenPosition: pos - Vector2(level.position.x + (level.width / 2), level.position.y), cameraPosition: game.cam.pos);
  }

  Vector2 screenToTileIsometric({
    required Vector2 screenPosition,
    required Vector2 cameraPosition,
    double zoom = 1,
  }) {
    final worldX = (screenPosition.x / zoom) + cameraPosition.x;
    final worldY = (screenPosition.y / zoom) + cameraPosition.y;

    final tileX = ((worldX / (tileSize.x / 2) + worldY / (tileSize.y / 2)) / 2);
    final tileY = ((worldY / (tileSize.y / 2) - worldX / (tileSize.x / 2)) / 2);

    return Vector2(tileX.toDouble() - (level.anchor.x / tileSize.x) + 1, tileY.toDouble() - (level.anchor.y / tileSize.y) + 1);
  }


  @override
  Vector2 toWorldPos(Vector2 grid) {
    return Vector2(
      (grid.x - grid.y) * (tileSize.x / 2),
      (grid.x + grid.y) * (tileSize.y / 2),
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
    return IsometricRectangleHitbox(position: position, size: size);
  }




}