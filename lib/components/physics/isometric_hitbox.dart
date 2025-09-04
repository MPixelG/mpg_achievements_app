import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/level.dart';

class IsometricHitbox extends PolygonHitbox {
  IsometricHitbox(Vector2 size, Level level, Vector2 offset)
      : super([
    level.isoToScreen(offset),
    level.isoToScreen(Vector2(size.x, 0) + offset),
    level.isoToScreen(Vector2(size.x, size.y) + offset),
    level.isoToScreen(Vector2(0, size.y) + offset),
  ], anchor: Anchor.topLeft, isSolid: true);
}