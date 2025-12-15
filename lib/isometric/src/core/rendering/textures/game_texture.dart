import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/isometric/src/components/animation/game_sprite_animation_ticker.dart';

import 'game_sprite.dart';


class GameTexture {
  late final String name;
  late final double? direction;
  
  late GameSprite sprite;
  
  late final AnimationType? animationType;
  int get frameCount => frames.length;
  late final List<GameSpriteAnimationFrame> frames;
  
  GameTexture(Image spritesheet, Image depthSpritesheet, this.name, this.direction, Vector2 srcPos, Vector2 size, {Vector2? srcPosDepth, Vector2? srcSizeDepth, this.animationType, List<GameSpriteAnimationFrame>? frames}){
    sprite = GameSprite(spritesheet, depthSpritesheet, srcSize: size, srcPosition: srcPos, srcSizeDepth: srcSizeDepth, srcPositionDepth: srcPosDepth);
    this.frames = frames ?? [];
  }
  
  GameSpriteAnimationTicker createTicker() => GameSpriteAnimationTicker(this);
  
  
  void dispose(){
    sprite.dispose();
  }
  
  @override
  String toString() => "$name: $direction [frames: $frameCount]";
}