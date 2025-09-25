import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_tiled_component.dart';

class ShadowComponent extends PositionComponent implements IsometricRenderable {

 final IsometricPlayer owner;

  ShadowComponent({required this.owner}){
    add(
      CircleComponent(
          radius: 8.0,
          paint: Paint()
            ..color = const Color(0x66000000),
          position: Vector2(0, 0)
      ),
    );
  }

  @override
  RenderCategory get renderCategory =>
      RenderCategory.characterEffect;

  @override
    Vector3 get gridFeetPos => owner.gridFeetPos;

}