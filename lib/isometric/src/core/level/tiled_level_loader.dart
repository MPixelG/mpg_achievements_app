import 'dart:async';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/isometric/src/core/level/tiled_level.dart';
import 'game_world.dart';
//todo refactor and integrate in new tiled_level

class LevelLoader {
  late final GameWorld gameWorld;
  late final TiledLevel levelData;
  late final Vector2 tileSize;

  LevelLoader({
    required this.gameWorld,
    required this.levelData,
    //for test now tilesize does not matter
    required this.tileSize,
  });

  void init() {
    // _spawnObjects();
    //_spawnCollisions();
  }

}
