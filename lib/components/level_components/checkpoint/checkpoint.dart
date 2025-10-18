import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:mpg_achievements_app/components/level_components/entity/animation/animated_character.dart';

import '../../../core/level/game_world.dart';
import '../../../core/math/iso_anchor.dart';
import '../../../state_management/providers/player_state_provider.dart';
import '../entity/animation/animation_manager.dart';
import '../entity/player.dart';

class Checkpoint extends AnimatedCharacter
    with
        CollisionCallbacks,
        AnimationManager,
        RiverpodComponentMixin {
  final int id;
  bool isActivated;

  Checkpoint({required this.id, this.isActivated = false, super.position}) : super(size: Vector3.all(1));

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        anchor: Anchor.topLeft,
        size: Vector2.all(64),
        collisionType: CollisionType.passive,
      ),
    );
    playAnimation("noFlag");
    anchor = Anchor3D.center;

    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final playerState = ref.read(playerProvider);

    if (!isActivated && other is Player) {
      if (playerState.lastCheckpoint == null ||
          playerState.lastCheckpoint!.id < id) {
        ref.read(playerProvider.notifier).setCheckpoint(this);

        // Safely find the parent Level component.
        final level = ancestors().whereType<GameWorld>().firstOrNull;

        // If the level is found, proceed with the logic.
        if (level != null) {
          for (final checkpoint in level.children.whereType<Checkpoint>()) {
            if (checkpoint.id <= id && !checkpoint.isActivated) {
              checkpoint.isActivated = true;
              checkpoint.playFlagOutAnimation();
              print("trying to play animation on older checkpoints");
            }
          }
        }
      }
    }
  }

  void playFlagOutAnimation() async {
    await playAnimation("out");
    playAnimation("outIdle");
  }

  @override
  String get componentSpriteLocation => "images/Items/Checkpoints/Checkpoint";

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.object;

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions(
      "outIdle",
      "Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)",
      textureSize: 64,
    ),
    AnimationLoadOptions(
      "out",
      "Items/Checkpoints/Checkpoint/Checkpoint (Flag Out)",
      textureSize: 64,
      stepTime: 0.04,
      loop: false,
    ),
    AnimationLoadOptions(
      "noFlag",
      "Items/Checkpoints/Checkpoint/Checkpoint (No Flag)",
      textureSize: 64,
      loop: false,
    ),
  ];
}
