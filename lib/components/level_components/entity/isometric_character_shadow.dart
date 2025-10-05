import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../../core/level/isometric/isometric_renderable.dart';
import '../../../core/level/isometric/isometric_tiled_component.dart';
import 'isometric_player.dart';

class ShadowComponent extends PositionComponent with IsometricRenderable {
  late Vector3 gridPos;
  final IsometricPlayer owner;

  ShadowComponent({required this.owner});

  @override
  FutureOr<void> onLoad() {
    gridPos = owner.gridFeetPos;
    position.setFrom(owner.absolutePosition.xy);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Continuously update the shadow's grid position to match the owner's.
    // This ensures correct render sorting as the player moves.
    gridPos = owner.gridFeetPos;
    if (owner.isFlippedHorizontally) {
      position.setFrom(
        owner.shadowAnchor.absolutePosition +
            Vector2(-owner.size.x / 2, owner.size.y),
      );
    } else {
      position.setFrom(
        owner.shadowAnchor.absolutePosition +
            Vector2(owner.size.x / 2, owner.size.y),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
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
  }

  @override
  RenderCategory get renderCategory => RenderCategory.characterEffect;

  @override
  Vector3 get gridFeetPos => owner.gridFeetPos - Vector3(0.5, 0.5, 1);

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 1);

  @override
  void Function(Canvas canvas) get renderAlbedo => (Canvas canvas) {
    renderTree(canvas);
  };

  @override
  void Function(Canvas canvas, Paint? overridePaint) get renderNormal =>
      (Canvas canvas, Paint? overridePaint) {};
}
