import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/animation/new_animated_character.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';

import '../isometric_tiled_component.dart';

class ExplosionEffect extends AnimatedCharacter {

  ExplosionEffect(Vector3 gridPos) : super(position: gridPos, size: Vector3(3, 3, 6), name: "Explosion Effect");

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
}
