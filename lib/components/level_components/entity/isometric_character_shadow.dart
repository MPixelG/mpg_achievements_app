import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ShadowComponent extends IsoPositionComponent {
  Player get owner => parent as Player;

  ShadowComponent([int priority = -1]) : super(size: Vector3(1, 1, 0.1)){
    this.priority = priority;
    position = Vector3.zero();
  }

  @override
  FutureOr<void> onLoad() {
    assert(parent is Player, 'ShadowComponent must be added to an Player');
    return super.onLoad();
  }

  @override
  void update(double dt){
    //anchor = Anchor3D(0, owner.position.z - owner.zGround, 0);
    super.update(dt);
  }

  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    // Convert the selected tile's grid coordinates into its center position in the isometric world.
    final tileW = tilesize.x;
    final tileH = tilesize.y;
    final halfTile = Vector2(tileW / 3, tileH / 6);

    // Define the four points
    final rect = Rect.fromLTRB(
      -halfTile.x,
      -halfTile.y,
      halfTile.x,
      halfTile.y,
    );

    // Define a paint for the highlight.
    final highlightPaint = Paint()
      ..color = Colors
          .black38 // Semi-transparent black
      ..style = PaintingStyle.fill;

    // Draw the oval inside the rectangle
    canvas.drawOval(rect, highlightPaint);
    super.render(canvas);

  }

  @override
  Vector3 get gridFeetPos => owner.gridFeetPos - Vector3(0.5, 0.5, owner.gridFeetPos.z - owner.zGround);

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 0);


  static final Vector3 defaultSize = Vector3(1, 1, 0.1);
}
