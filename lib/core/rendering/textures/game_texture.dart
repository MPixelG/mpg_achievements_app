import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart' show mustCallSuper;


class GameTexture {
  late final String name;
  late final double? direction;
  int get width => _albedoMap.image.width;
  int get height => _albedoMap.image.height;

  late Sprite _albedoMap;
  late Sprite _depthMap;


  GameTexture(Image spritesheet, Image depthSpritesheet, this.name, Vector2 srcPos, Vector2 size, this.direction){
    _albedoMap = Sprite(spritesheet, srcPosition: srcPos, srcSize: size);
    _depthMap = Sprite(depthSpritesheet, srcPosition: srcPos, srcSize: size);
  }

  @mustCallSuper
  void dispose(){
    _albedoMap.image.dispose();
    _depthMap.image.dispose();
  }
}