import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/animation/new_animated_character.dart';

class TestSpriteEntity extends AnimatedCharacter {
  TestSpriteEntity({
    required super.textureBatch,
    super.current,
    super.autoResize,
    super.playing = true,
    super.removeOnFinish = const {},
    super.autoResetTicker = true,
    super.paint,
    super.position,
    required super.size,
    super.scale,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) : super(name: "Test Sprite Entity");
  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]){
    current = "idle";
    super.render(canvas, normalCanvas, getNormalPaint);
  }
}