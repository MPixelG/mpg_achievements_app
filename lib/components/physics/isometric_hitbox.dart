import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level/level.dart';

class IsometricHitbox extends PolygonHitbox{
  IsometricHitbox(Vector2 size, Level level) : super ([

    Vector2(0, 0),
    level.toWorldPos(Vector2(size.x, 0)),
    level.toWorldPos(size),
    level.toWorldPos(Vector2(0, size.y)),

  ], anchor: Anchor.topLeft, position: Vector2.zero());
}