import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/components/level/level.dart';

///an IsometricHitbox is a hitbox for the isometric level. its used for players and collision blocks
class IsometricHitbox extends PolygonHitbox{
  IsometricHitbox(Vector2 size, Level level, {Anchor? anchor}) : super ([

    Vector2(0, 0),
    level.toWorldPos(Vector2(size.x, 0)),
    level.toWorldPos(size),
    level.toWorldPos(Vector2(0, size.y)),

  ], anchor: anchor, position: Vector2.zero()){
    size.x = Vector2.zero().distanceTo(level.toWorldPos(Vector2(size.x, 0)));
    size.y = Vector2.zero().distanceTo(level.toWorldPos(Vector2(0, size.y)));
  }
}