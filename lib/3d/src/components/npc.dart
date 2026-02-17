import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:mpg_achievements_app/3d/src/components/animated_game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/npc_data.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';

import '../../../core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';


class Npc extends AnimatedGameCharacter<NpcData>{

  Npc({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    required super.modelPath,
    super.name,
  });

  @override
  double get modelScale => 0.0005;

  @override
  NpcData initState() => NpcData();

  @override
  void tickClient(double dt) {

    game.getTransformNotifier(entityId).updateTransform(positionOfAnchor(Anchor3D.topLeftLeft), newRotZ: rotationZ);
    //todo implement
     super.tickClient(dt);
  }

  @override
  FutureOr<void> onLoad() {
    hitbox = RectangleHitbox3D(size: size);
    hitbox.collisionType = CollisionType.active;
    return super.onLoad();
  }
}