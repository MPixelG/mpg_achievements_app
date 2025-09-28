import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Chunk;
import 'package:mpg_achievements_app/components/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';

import '../../../components/util/isometric_utils.dart';
import '../../../mpg_pixel_adventure.dart';
import '../game_world.dart';
import 'isometric_renderable.dart';
import 'isometric_tiled_component.dart';
import 'tile_effects/highlighted_tile.dart';

class TileSelectionResult {
  final Vector3 gridPosition;
  final Gid tileGid; // The Gid object from Tiled, which contains the tile ID

  TileSelectionResult(this.gridPosition, this.tileGid);
}

class IsometricWorld extends GameWorld {
  late IsometricTileGrid tileGrid;
  Vector2? selectedTile;
  TileHighlightRenderable? highlightedTile;

  // Example isometric tile size (width, height)
  IsometricWorld({required super.levelName, required super.calculatedTileSize});

  @override
  Future<void> onLoad() async {
    // Initialize the player as an IsometricPlayer
    player = IsometricPlayer(playerCharacter: 'Pink Man');

    await super.onLoad();
    //find the collision layer
    final collisionLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    tileGrid = IsometricTileGrid(
      level.tileMap.map.width,
      level.tileMap.map.height,
      tilesize
          .xy, //setting the tile size to match the isometric tile dimensions
      collisionLayer,
      this,
    );
  }

  @override
  Future<TiledComponent> createTiledLevel(
    String filename,
    Vector2 destTilesize,
  ) async {
    return IsometricTiledComponent(
      (await TiledComponent.load(filename, destTilesize)).tileMap,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    removeWhere((component) => component is TileHighlightRenderable);

    // Convert the tap position from screen space to world space.
    final screenPositionTap = event.localPosition;
    final worldPositionTap = level.toLocal(screenPositionTap);
    Vector2? selectedTile = toGridPos(worldPositionTap)..floor();

    print("pos: $selectedTile");

    // Use the function to find the top-most tile.
    final selectionResult = getTopmostTileAtGridPos(selectedTile);

    // Remove the old highlight.

    if (selectionResult != null) {
      // A tile was successfully selected!

      // Create the highlight with both grid position and layer index.
      final highlightedTile = TileHighlightRenderable(
        selectionResult.gridPosition,
      );

      // Position the highlight using the layer-aware toWorldPos.
      highlightedTile.position = toWorldPos(
        selectionResult.gridPosition,
      ); // Center the highlight on the tile
      print("Highlight position set to: ${highlightedTile.position}");

      add(highlightedTile);

      print(
        "Selected tile at ${selectionResult.gridPosition.xy} on layer ${selectionResult.gridPosition.z}",
      );
    } else {
      // No tile was found at this position (clicked on empty space).
      highlightedTile = null;
      selectedTile = null;
      print("No tile selected.");
    }
  }

  @override
  void renderFromCamera(Canvas canvas) {
    assert(CameraComponent.currentCamera != null);
    super.renderTree(canvas);

    if (level is! IsometricTiledComponent) return;

    for (final child in children.where(
      (element) => element is! IsometricRenderable && element != level,
    )) {
      child.renderTree(canvas);
    }

    (level as IsometricTiledComponent).renderComponentsInTree(
      canvas,
      children.whereType<IsometricRenderable>(),
      CameraComponent.currentCamera!.viewfinder.position,
      CameraComponent.currentCamera!.viewport.size,
    );
  }

  @override
  bool checkCollisionAt(Vector2 gridPos) {
    // Access the 'Collisions' layer from the Tiled map
    final layer = level.tileMap.map.layerByName('Collisions') as ObjectGroup?;
    if (layer == null) {
      return false;
    }
    // Check boundaries of the tile data if outside return true for collision

    for (var value in layer.objects) {
      assert(
        value.isRectangle,
        'Only rectangle objects are supported in the Collisions layer.',
      );

      Vector2 gridObjectPos = toGridPos(value.position);

      if (Rect.fromPoints(
        gridObjectPos.toOffset(),
        gridObjectPos.toOffset() + (value.size..divide(tilesize.xz)).toOffset(),
      ).contains(gridPos.toOffset())) {
        return true;
      }
    }
    return false;
  }

  // Finds the top-most, non-empty tile at a given grid coordinate.
  // It iterates through the map layers from top to bottom.
  TileSelectionResult? getTopmostTileAtGridPos(Vector2 gridPos) {
    final map = game.gameWorld.level.tileMap.map;
    final x = gridPos.x.toInt();
    final y = gridPos.y.toInt();

    // Iterate from the top layer (highest index) down to the bottom.
    for (var i = map.layers.length - 1; i >= 0; i--) {
      final layer = map.layers[i];

      // We only care about tile layers for selection.
      if (layer is TileLayer) {
        // Make sure the coordinates are within the bounds of this layer.
        if (x >= 0 && x < layer.width && y >= 0 && y < layer.height) {

          // Tiled stores tile data in [row][column] format, so we use [y][x].
          final gid = layer.tileData![y][x];

          // A GID of 0 means the tile is empty. If it's not empty, we've found our target! that means the first tile we find in the top-most layer is our tile that we look for
          if (gid.tile != 0) {
            // Success! Return all the info about the tile we found.
            return TileSelectionResult(
              Vector3(gridPos.x, gridPos.y, i.toDouble()),
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
