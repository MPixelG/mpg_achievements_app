import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

@Deprecated("use core/rendering/game_sprite instead!")
interface class GameSprite {
  Sprite albedo;
  Sprite? normalAndDepth;

  GameSprite(this.albedo, [this.normalAndDepth]);
}

Image get noTextureImage =>
    Flame.images.fromCache("Pixel_ArtTop_Down/noTextureBlock.png");
