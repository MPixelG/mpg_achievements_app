import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ExplosionEffect extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, AnimationManager {

  ExplosionEffect({super.position});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // The explosion's visual center should align with its position.
    anchor = Anchor.center;

    // Play the animation once, and when it's complete, remove this component.
    await playAnimation('explosion_1');
    removeFromParent();
  }


  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.effect;

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

/*
//Manually draw the current animation frame
    final sprite = animationTicker?.getSprite(); // Get the sprite for the current frame
    if (sprite != null) {

      final spriteCenterOffset = sprite.srcSize;// Offset to center the sprite
      final diamondCenter = Vector2(0, halfTile.y); //bottom center of the diamond
      final spriteDrawPosition = diamondCenter - Vector2(spriteCenterOffset.x / 2, spriteCenterOffset.y);// Center the sprite above the diamond

      // Render the sprite at the calculated position.
      sprite.render(
        canvas,
        position: spriteDrawPosition,
        size: sprite.srcSize,
      );

      }
 */