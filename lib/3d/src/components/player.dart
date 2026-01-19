import 'dart:async';
import 'dart:math';
import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';

class Player extends GameCharacter<PlayerData> {

  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.asset,
  });

  @override
  PlayerData initState() => PlayerData();
  
  @override
  void tickClient(double dt) {
    position.x = cos(DateTime.now().millisecondsSinceEpoch / 1000) * 20;
    position.z = sin(DateTime.now().millisecondsSinceEpoch / 1000) * 20;
    print("update!");
    super.tickClient(dt);
  }
  
  
  @override
  FutureOr<void> onLoad() async {
    asset = await thermion?.loadGltf("assets/3D/prototyping_assets/Pieces/Bee.glb");
    print("asset: ${asset.toString()}");
  }
}