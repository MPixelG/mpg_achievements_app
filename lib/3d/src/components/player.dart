import 'dart:async';
import 'dart:math';

import 'package:mpg_achievements_app/3d/src/components/animated_game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';
import 'package:vector_math/vector_math_64.dart';

class Player extends AnimatedGameCharacter<PlayerData> {

  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.modelPath = "assets/3D/character/character_animated_v1.glb",
    super.name,
  });

  @override
  PlayerData initState() => PlayerData();

  Vector3? lastPosition;
  //update is called in the superclass entity first which then calls the tickClient method in the player, the player updates it's postition
  //then the entity class calls it's own tickClient()-method which updates the position of the player
  @override
  void tickClient(double dt) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;

    position.x = cos(t) * 10;
    position.z = sin(t) * 10;

    final velocity = position - (lastPosition ?? position);

    if (velocity.length2 > 0.0001) {

      final dx = velocity.x;
      final dz = velocity.z;

      final targetYaw = atan2(dx, dz);
      final diff = (targetYaw - rotationZ + pi) % (2 * pi) - pi;

      rotationZ += diff * 0.1;
    }

    lastPosition = position.clone();

    //rotationZ = atan2(vz, vx) + pi / 2; // oder -pi/2
    super.tickClient(dt);
  }
  
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    print("animations: ${await getAnimationNames()}");
    playAnimation("walking", loop: true);
    return;
  }
  
}