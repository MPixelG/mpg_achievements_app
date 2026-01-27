import 'package:mpg_achievements_app/3d/src/components/animated_game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/npc_data.dart';


class Npc extends AnimatedGameCharacter<NpcData>{

  Npc({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.modelPath = "assets/3D/small_bee.glb",
    super.name,
  });

  @override
  NpcData initState() => NpcData();

  @override
  void tickClient(double dt) {

    game.getTransformNotifier(entityId).updateTransform(position, newRotZ: rotationZ);
    //todo implement
     super.tickClient(dt);
  }
}