import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'explosion_effect.dart';

class TileHighlightRenderable extends IsoPositionComponent
    with
        RiverpodComponentMixin,
        CollisionCallbacks,
        HasGameReference<PixelAdventure> {
  bool done = false;

  TileHighlightRenderable({super.isoPosition});

  late final Vector2 tileSize;

  ExplosionEffect? explosionEffect;
  @override
  void onLoad() {
    // Position the highlight based on the grid position and tile size.
    tileSize = game.gameWorld.tileGrid.tileSize;
    explosionEffect = ExplosionEffect(this, isoPosition);
    add(explosionEffect!);
  }

  @override
  void update(double dt) {
    if (explosionEffect?.done ?? false) {
      done = true;
    }
  }

  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas);
    // Convert the selected tile's grid coordinates into its center position in the isometric world.
    final tileW = tilesize.x;
    final tileH = tilesize.y;
    final halfTile = Vector2(tileW / 2, tileH / 2);

    // Define the four vertices of the isometric diamond for the tile.
    List<Offset> diamond = [
      (Vector2(0, -halfTile.y / 2)).toOffset(), // Top center
      (Vector2(halfTile.x, 0)).toOffset(), // Middle right
      (Vector2(0, halfTile.y / 2)).toOffset(), // Bottom center
      (Vector2(-halfTile.x, 0)).toOffset(), // Middle left
    ];

    // Define a paint for the highlight.
    final highlightPaint = Paint()
      ..color = Colors.yellow
          .withAlpha(125) // Semi-transparent yellow
      ..style = PaintingStyle.fill;

    // Draw the diamond shape on the canvas.
    canvas.drawVertices(
      Vertices(VertexMode.triangleFan, diamond),
      BlendMode.srcOver, // A standard blend mode for overlays.
      highlightPaint,
    );
  }

  @override
  Vector3 get isoSize => Vector3(1, 1, 0);

}
