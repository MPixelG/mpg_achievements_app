import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';

import '../util/isometric_utils.dart';

class IsometricHitbox extends PolygonHitbox {
  IsometricHitbox(Vector2 size, Vector2 offset)
      : super([
    isoToScreen(offset),
    isoToScreen(Vector2(size.x, 0) + offset),
    isoToScreen(Vector2(size.x, size.y) + offset),
    isoToScreen(Vector2(0, size.y) + offset),
  ], anchor: Anchor.topLeft, isSolid: true);
}