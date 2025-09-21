import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

interface class GameSprite {
  Sprite albedo;
  Sprite? normalAndDepth;

  GameSprite(this.albedo, [this.normalAndDepth]);
}
Image get noTextureImage => Flame.images.fromCache("Pixel_ArtTop_Down/noTextureBlock.png");