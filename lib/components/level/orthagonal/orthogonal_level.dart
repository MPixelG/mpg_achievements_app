import 'package:flame/src/collisions/hitboxes/rectangle_hitbox.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:vector_math/vector_math.dart';

class OrthogonalLevel extends Level{
  OrthogonalLevel({required super.levelName, required super.player, required tileSize});

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

}