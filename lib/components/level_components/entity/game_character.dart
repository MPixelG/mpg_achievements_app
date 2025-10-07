import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level_components/entity/animation/animated_character.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'animation/animation_manager.dart';

abstract class GameCharacter extends AnimatedCharacter
    with HasGameReference<PixelAdventure>, AnimationManager {

  GameCharacter({super.position, super.anchor});
  Vector2 get gridPos =>
      Vector2(isoPosition.x / tilesize.x, isoPosition.y / tilesize.y);

  set gridPos(Vector2 newGridPos) {
    isoPosition.xy = newGridPos * tilesize.x;
  }
}