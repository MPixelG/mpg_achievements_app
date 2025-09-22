import 'dart:async';

import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:vector_math/vector_math.dart';

class OrthogonalWorld extends GameWorld{
  OrthogonalWorld({required super.levelName, required super.calculatedTileSize});

  @override
  Future<void> onLoad() async {
    player = Player(playerCharacter: 'Virtual Guy');
    await super.onLoad();
  }

  @override
  Vector2 toGridPos(Vector2 pos) {
    return Vector2(pos.x / tilesize.x, pos.y / tilesize.y)..floor();
  }

  @override
  Vector2 toWorldPos(Vector2 pos, [double z = 0]) {
    return Vector2(pos.x * tilesize.x, pos.y * tilesize.y)..floor();
  }

  @override
  bool checkCollisionAt(Vector2 gridPos) {
    throw UnimplementedError();
  }
}