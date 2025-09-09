import 'dart:async';
import 'package:mpg_achievements_app/components/entity/player.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import 'package:vector_math/vector_math.dart';

class OrthogonalWorld extends GameWorld{
  OrthogonalWorld({required super.levelName, required super.tileSize});

  @override
  Future<void> onLoad() async {
    player = Player(playerCharacter: 'Virtual Guy');
    await super.onLoad();
  }

  @override
  Vector2 toGridPos(Vector2 pos) {
    return Vector2(pos.x / tileSize.x, pos.y / tileSize.y)..floor();
  }

  @override
  Vector2 toWorldPos(Vector2 pos) {
    return Vector2(pos.x * tileSize.x, pos.y * tileSize.y)..floor();
  }

  @override
  bool checkCollisionAt(Vector2 gridPos) {
    throw UnimplementedError();
  }
}