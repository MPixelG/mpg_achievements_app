import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../animation/animation_manager.dart';

abstract class GameCharacter extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, AnimationManager {
  GameCharacter({super.position, super.anchor});
  Vector2 get gridPos =>
      Vector2(position.x / tilesize.x, position.y / tilesize.y);

  set gridPos(Vector2 newGridPos) {
    position = Vector2(newGridPos.x * tilesize.x, newGridPos.y * tilesize.y);
  }
}
