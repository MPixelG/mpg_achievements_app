import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/npc_data.dart';

class Npc extends GameCharacter<NpcData>{

  Npc({
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
  NpcData initState() => NpcData();

  @override
  void tickClient(double dt) {
    //todo implement
     super.tickClient(dt);
  }
}