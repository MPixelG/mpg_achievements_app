import 'dart:ui';

interface class GameSprite {
  Image texture;
  Image? normalTexture;

  GameSprite(this.texture, [this.normalTexture]);
}