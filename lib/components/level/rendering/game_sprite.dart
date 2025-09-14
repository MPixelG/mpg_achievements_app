import 'dart:ui';

import 'package:flame/components.dart';

interface class GameSprite {
  Sprite sprite;
  Sprite? normalMapSprite;

  Image get renderImage => sprite.image;
  Image? get normalMap => normalMapSprite?.image;

  GameSprite(this.sprite, [this.normalMapSprite]);
}