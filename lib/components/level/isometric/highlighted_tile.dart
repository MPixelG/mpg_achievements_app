import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometricRenderable.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometricTiledComponent.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


class TileHighlightRenderable extends SpriteAnimationGroupComponent with RiverpodComponentMixin, IsometricRenderable, CollisionCallbacks, HasGameReference<PixelAdventure>, AnimationManager {

  final Vector2 gridPos;
  final int zIndex;


  TileHighlightRenderable(this.gridPos, this.zIndex);

  late final Vector2 tileSize;

  @override
  void onLoad() {
    // Position the highlight based on the grid position and tile size.
    tileSize = game.gameWorld.tileGrid.tileSize;

    playAnimation("explosion_1");
  }


  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Convert the selected tile's grid coordinates into its center position in the isometric world.
    final tileW = tileSize.x;
    final tileH = tileSize.y;
    final halfTile = Vector2(tileW / 2, tileH / 2);


    // Define the four vertices of the isometric diamond for the tile.
    List<Offset> diamond = [
      (Vector2(0, -halfTile.y)).toOffset(),   // Top center
      (Vector2(halfTile.x, 0)).toOffset(),   // Middle right
      (Vector2(0, halfTile.y)).toOffset(),   // Bottom center
      (Vector2(-halfTile.x, 0)).toOffset(),  // Middle left
    ];


    // Define a paint for the highlight.
    final highlightPaint = Paint()
      ..color = Colors.yellow.withAlpha(125) // Semi-transparent yellow
      ..style = PaintingStyle.fill;


    // Draw the diamond shape on the canvas.
    canvas.drawVertices(
      Vertices(VertexMode.triangleFan, diamond),
      BlendMode.srcOver, // A standard blend mode for overlays.
      highlightPaint,
    );

  }

  @override
  Vector2 get gridFeetPos => gridPos;

  @override
  int get renderPriority => zIndex;

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions(
      "explosion_1",
      "$componentSpriteLocation/explosion1d",
      textureSize: 128,
      loop: false,
      stepTime: 0.1,
      ),
   ];


  @override
  String get componentSpriteLocation => "Explosions/explosion1d";

  @override

  AnimatedComponentGroup get group => AnimatedComponentGroup.effect;

  @override
  RenderCategory get renderCategory => RenderCategory.tileHighlight;

}