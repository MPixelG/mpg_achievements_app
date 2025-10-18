import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level_components/entity/animation/animated_character.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';

import '../../../../components/level_components/entity/animation/animation_manager.dart';
import '../isometric_tiled_component.dart';
import 'highlighted_tile.dart';

class ExplosionEffect extends AnimatedCharacter with AnimationManager {
  TileHighlightRenderable tileHighlight;

  ExplosionEffect(this.tileHighlight, Vector3 gridPos) : super(position: gridPos, size: Vector3(3, 3, 6));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor3D.bottomCenter;
    // The explosion's visual center should align with its position.
    // Play the animation once, and when it's complete, remove this component.
    playAnimation('explosion_1');
    animationTicker?.onComplete = () {
      done = true;
      (game.gameWorld.level as IsometricTiledComponent).forceRebuildCache();
    };
  }

  bool done = false;

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.entity;

  @override
  String get componentSpriteLocation => 'Explosions/explosion1d';

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions(
      "explosion_1",
      "$componentSpriteLocation/explosion1d", // Use the path directly
      textureSize: 128,
      loop: false,
      stepTime: 0.1,
    ),
  ];
}
