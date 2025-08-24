import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../state_management/providers/playerStateProvider.dart';

class Checkpoint extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, CollisionCallbacks, AnimationManager, RiverpodComponentMixin {
  final int id;
  bool isActivated;

  Checkpoint({required this.id, this.isActivated = false, super.position});

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
        anchor: Anchor.topLeft,
        size: Vector2.all(64),
        collisionType: CollisionType.passive)
    );
    playAnimation("noFlag");
    anchor = Anchor.center;


    return super.onLoad();
  }

 @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    final playerState = ref.watch(playerProvider);
    // if the checkpoint hasn't yet been activated and the player is colliding, we continue
    if (!isActivated && other is Player) {
      // id (represents gameplay progress) has to be higher so that the player always spawns at the latest checkpoint
      if (playerState.lastCheckpoint == null || playerState.lastCheckpoint!.id < id) {
        isActivated = true;
        ref.read(playerProvider.notifier).setCheckpoint(this);
        playFlagOutAnimation();
      }
    }
  }

  void playFlagOutAnimation() async{

    await playAnimation("out");
    playAnimation("outIdle");

  }

  @override
  String get componentSpriteLocation => "images/Items/Checkpoints/Checkpoint";

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.object;

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions("outIdle", "Items/Checkpoints/Checkpoint/Checkpoint (Flag Idle)", textureSize: 64),
    AnimationLoadOptions("out", "Items/Checkpoints/Checkpoint/Checkpoint (Flag Out)", textureSize: 64, stepTime: 0.04, loop: false),
    AnimationLoadOptions("noFlag", "Items/Checkpoints/Checkpoint/Checkpoint (No Flag)", textureSize: 64, loop: false),
  ];
}
