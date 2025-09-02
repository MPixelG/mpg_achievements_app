import 'package:flame/components.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../animation/animation_manager.dart';

abstract class GameCharacter extends SpriteAnimationGroupComponent with HasGameReference<PixelAdventure>, AnimationManager{
  GameCharacter({super.position});
}