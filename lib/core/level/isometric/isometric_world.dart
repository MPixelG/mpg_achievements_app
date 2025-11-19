import 'dart:developer';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Chunk;
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/enemy/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/level_components/entity/isometric_character_shadow.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/core/level/game_world.dart';
import 'package:mpg_achievements_app/core/physics/collision_block.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';


import 'isometric_renderable.dart';
import 'isometric_tiled_component.dart';
import 'tile_effects/highlighted_tile.dart';

class TileSelectionResult {
  final int x;
  final int y;
  final int z;
  final Gid tileGid; // The Gid object from Tiled, which contains the tile ID

  TileSelectionResult(this.x, this.y, this.z, this.tileGid);

  Vector3 get pos => Vector3(x.toDouble(), y.toDouble(), z.toDouble());
}

class IsometricWorld extends GameWorld {
  Vector3? selectedTile;
  TileHighlightRenderable? highlightedTile;
  late ShadowComponent? shadow;

  // Example isometric tile size (width, height)
  IsometricWorld({required super.levelName, required super.calculatedTileSize});

  @override
  Future<void> onLoad() async {
    // Initialize the player as an IsometricPlayer
    player = Player(playerCharacter: 'Player');
    player2 = Player(playerCharacter: 'BubbleMaster');

    await super.onLoad();
    //find the collision layer
    final collisionLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    tileGrid = IsometricTileGrid(
      level.tileMap.map.width,
      level.tileMap.map.height,
      tilesize.xy, //setting the tile size to match the isometric tile dimensions
      collisionLayer,
      this,
    );
  }

  List<CollisionBlock> tmpBlocks = [];
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    removeWhere((component) => component is TileHighlightRenderable);

    // Convert the tap position from screen space to world space.
    final screenPositionTap = event.localPosition;
    final worldPositionTap = level.toLocal(screenPositionTap);
    Vector2? selectedTile = toGridPos(worldPositionTap)..floor();

    log("pos: $selectedTile");


    // Use the function to find the top-most tile.
    final selectionResult = getTopmostTileAtGridPos(selectedTile);

    // Remove the old highlight.

    if (selectionResult != null) {
      // A tile was successfully selected!

      // Create the highlight with both grid position and layer index.
      final highlightedTile = TileHighlightRenderable(
        position: selectionResult.pos,
      );

      // Position the highlight using the layer-aware toWorldPos.
      highlightedTile.position = selectionResult.pos;
      log("Highlight position set to: ${highlightedTile.position}");

      tmpBlocks.add(CollisionBlock(position: selectionResult.pos, size: Vector3.all(1)));
      add(tmpBlocks.last);


      add(highlightedTile); //todo clicking on a tile lower on the screen than the player, the player gets drawn on top of everything
    } else {
      // No tile was found at this position (clicked on empty space).
      highlightedTile = null;
      selectedTile = null;
      log("No tile selected.");
    }
  }

  @override
  void update(double dt){
    //print("block: ${tmpBlocks.lastOrNull?.hitbox.aabb.min} - ${tmpBlocks.lastOrNull?.hitbox.aabb.max}");
    //print("player: ${player.hitbox.aabb.min} - ${player.hitbox.aabb.max}");
    super.update(dt);
  }

  @override
  void renderFromCamera(Canvas canvas) {
    assert(CameraComponent.currentCamera != null);

    for (final child in children.where(
          (element) => element is! IsometricRenderable && element != level,
    )) {
      child.renderTree(canvas);
    }

    (level as IsometricTiledComponent).renderComponentsInTree(
      canvas,
      children.whereType<IsometricRenderable>().toList(),
      CameraComponent.currentCamera!.viewfinder.position - (CameraComponent.currentCamera!.viewport.virtualSize/2),
      CameraComponent.currentCamera!.viewport.virtualSize,
    );
  }

  @override
  bool checkCollisionAt(Vector3 gridPos) {
    // Access the 'Collisions' layer from the Tiled map
    final layer = level.tileMap.map.layers.whereType<TileLayer>().toList().elementAtOrNull(gridPos.y.toInt());
    if (layer == null) {
      return false;
    }
    // Check boundaries of the tile data if outside return true for collision

    if(layer.tileData == null){
      throw UnimplementedError("chunking is not implemented yet!");
    }else {
      if(gridPos.x.toInt() < 0 || gridPos.x.toInt() >= layer.width ||
          gridPos.z.toInt() < 0 || gridPos.z.toInt() >= layer.height){
        return true;
      }
      final int gid = layer.tileData![gridPos.z.toInt()][gridPos.x.toInt()].tile;

      return gid != 0;
    }
  }

  // Finds the top-most, non-empty tile at a given grid coordinate.
  // It iterates through the map layers from top to bottom.
  TileSelectionResult? getTopmostTileAtGridPos(Vector2 gridPos) {
    final map = game.gameWorld.level.tileMap.map;
    final int x = gridPos.x.toInt();
    final int z = gridPos.y.toInt();

    final int layerAmount = map.layers.length-1;

    // Iterate from the top layer (highest index) down to the bottom.
    for (var i = layerAmount; i >= 0; i--) {
      final layer = map.layers[i];

      // We only care about tile layers for selection.
      if (layer is TileLayer) {
        // Make sure the coordinates are within the bounds of this layer.
        if (x >= 0 && x < layer.width && z >= 0 && z < layer.height) {
          // Tiled stores tile data in [row][column] format, so we use [y][x].
          final gid = layer.tileData![z][x];

          // A GID of 0 means the tile is empty. If it's not empty, we've found our target! that means the first tile we find in the top-most layer is our tile that we look for
          if (gid.tile != 0) {
            // Success! Return all the info about the tile we found.
            return TileSelectionResult(
              x+i, i, z+i,
              gid,
            );
          }
        }
      }
    }

    // If we looped through all layers and found nothing, return null.
    return null;
  }
}
