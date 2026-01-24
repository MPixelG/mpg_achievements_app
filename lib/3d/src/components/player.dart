import 'dart:math';

import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';

class Player extends GameCharacter<PlayerData> {

  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.modelPath = "assets/3D/character.glb",
    super.name,
  });

  @override
  PlayerData initState() => PlayerData();

  //update is called in the superclass entity first which then calls the tickClient method in the player, the player updates it's postition
  //then the entity class calls it's own tickClient()-method which updates the position of the player
  @override
  void tickClient(double dt) {
    position.x = cos(DateTime.now().millisecondsSinceEpoch / 1000) * 10;
    position.z = sin(DateTime.now().millisecondsSinceEpoch / 1000) * 10;
    rotationY = sin(DateTime.now().millisecondsSinceEpoch / 1000) * 10; //lol
    super.tickClient(dt);
  }
}