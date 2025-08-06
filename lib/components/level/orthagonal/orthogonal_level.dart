import 'package:flame/src/collisions/hitboxes/rectangle_hitbox.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:vector_math/vector_math.dart';

class OrthogonalLevel extends Level{
  OrthogonalLevel({required super.levelName, required super.player});

  @override
  Vector2 toGridPos(Vector2 pos) {
    return Vector2(pos.x / tileSize.x, pos.y / tileSize.y)..floor();
  }

  @override
  Vector2 toWorldPos(Vector2 pos) {
    return Vector2(pos.x * tileSize.x, pos.y * tileSize.y)..floor();
  }

  @override
  bool checkCollisionAt(Vector2 point, Vector2 center, Vector2 size) {
    throw UnimplementedError();
  }

  @override
  RectangleHitbox createHitbox({Vector2? position, Vector2? size}) {
    return RectangleHitbox(position: position, size: size);
  }

  @override
  Vector2 screenToTileIsometric({required Vector2 screenPosition, required Vector2 cameraPosition, double zoom = 1}) {
    // TODO: implement screenToTileIsometric
    throw UnimplementedError();
  }
}