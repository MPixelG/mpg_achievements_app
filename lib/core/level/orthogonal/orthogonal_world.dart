import 'dart:async';

import 'package:vector_math/vector_math.dart';

import '../../../components/level_components/entity/player.dart';
import '../game_world.dart';

class OrthogonalWorld extends GameWorld {
  OrthogonalWorld({
    required super.levelName,
    required super.calculatedTileSize,
  });

  @override
  Future<void> onLoad() async {
    player = Player(playerCharacter: 'Virtual Guy');
    await super.onLoad();
  }

  @override
  bool checkCollisionAt(Vector2 gridPos) {
    throw UnimplementedError();
  }
}