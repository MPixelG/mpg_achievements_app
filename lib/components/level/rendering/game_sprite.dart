import 'dart:ui';

import 'package:flame/components.dart';

interface class GameSprite {
  Image texture;
  Image? normalTexture;

  GameSprite(this.texture, [this.normalTexture]);
}