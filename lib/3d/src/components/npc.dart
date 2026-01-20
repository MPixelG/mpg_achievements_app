import 'dart:async';
import 'dart:math';
import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/npc_data.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';

class Npc extends GameCharacter<NpcData> {

  Npc({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.asset,
    super.modelPath,
  });

  @override
  NpcData initState() => NpcData();

  @override
  void tickClient(double dt) {
    //todo implement
     super.tickClient(dt);
  }


  @override
  FutureOr<void> onLoad() async {
    asset = await thermion?.loadGltf(this.modelPath!);
    print("asset: ${asset.toString()}");
  }
}