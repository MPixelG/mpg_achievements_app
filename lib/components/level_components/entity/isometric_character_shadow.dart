import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../../core/level/isometric/isometric_renderable.dart';
import '../../../core/level/isometric/isometric_tiled_component.dart';
import 'isometric_player.dart';

class ShadowComponent extends IsoPositionComponent with IsometricRenderable {
  IsometricPlayer get owner => parent as IsometricPlayer;

  ShadowComponent([int priority = -1]){
    this.priority = -10000;
    isoPosition = Vector3.zero();
  }

  @override
  void update(double dt){
    anchor = Anchor(0, owner.isoPosition.z - owner.zGround + owner.size.y - 3);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
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
  RenderCategory get renderCategory => RenderCategory.characterEffect;

  @override
  Vector3 get gridFeetPos => owner.gridFeetPos - Vector3(0.5, 0.5, owner.gridFeetPos.z - owner.zGround);

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 0);

  @override
  void Function(Canvas canvas) get renderAlbedo => (Canvas canvas) {
    renderTree(canvas);
  };

  @override
  void Function(Canvas canvas, Paint? overridePaint) get renderNormal =>
      (Canvas canvas, Paint? overridePaint) {};
}
