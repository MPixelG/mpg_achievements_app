import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level/isometric/tile_effects/explosion_effect.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../isometric_renderable.dart';
import '../isometric_tiled_component.dart';

class TileHighlightRenderable extends PositionComponent
    with
        RiverpodComponentMixin,
        IsometricRenderable,
        CollisionCallbacks,
        HasGameReference<PixelAdventure> {
  final Vector3 gridPos;

  bool done = false;

  TileHighlightRenderable(this.gridPos);

  late final Vector2 tileSize;

  ExplosionEffect? explosionEffect;
  @override
  void onLoad() {
    // Position the highlight based on the grid position and tile size.
    tileSize = game.gameWorld.tileGrid.tileSize;
    print("loaded!");
    explosionEffect = ExplosionEffect(this, gridPos);
    add(explosionEffect!);
  }

  @override
  void update(double dt) {
    if (explosionEffect?.done ?? false) {
      done = true;
    }
  }

  @override
  void render(Canvas canvas) {
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
  Vector3 get gridFeetPos => gridPos;

  @override
  RenderCategory get renderCategory => RenderCategory.tileHighlight;

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(0.1, 0.1, 1);

  @override
  void Function(Canvas canvas, Paint? overridePaint)? get renderNormal =>
      (Canvas canvas, Paint? overridePaint) {
        renderTree(canvas);
      };
  @override
  void Function(Canvas canvas, {Vector2? position, Vector2? size})
  get renderAlbedo => (Canvas canvas, {Vector2? position, Vector2? size}) {};
}
