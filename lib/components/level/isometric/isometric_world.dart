import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';

import '../../../mpg_pixel_adventure.dart';
import 'isometric_renderable.dart';
import 'isometric_tiled_component.dart';
import 'tile_effects/highlighted_tile.dart';

class TileSelectionResult {
  final Vector3 gridPosition;
  final Gid tileGid;// The Gid object from Tiled, which contains the tile ID

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
      tilesize.xy,//setting the tile size to match the isometric tile dimensions
      collisionLayer,
      this,
    );
  }

  @override
  Future<TiledComponent> createTiledLevel(String filename, Vector2 destTilesize) async{
    return IsometricTiledComponent((await TiledComponent.load(filename, destTilesize)).tileMap);
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
        selectionResult.gridPosition.xy,
        selectionResult.gridPosition.z,
      ); // Center the highlight on the tile
      print("Highlight position set to: ${highlightedTile.position}");

      add(highlightedTile);

      print("Selected tile at ${selectionResult
          .gridPosition.xy} on layer ${selectionResult.gridPosition.z}");
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

    if(level is! IsometricTiledComponent) return;

    for (final child in children.where((element) => element is! IsometricRenderable && element != level)) {
      child.renderTree(canvas);
    }

    (level as IsometricTiledComponent).renderComponentsInTree(canvas, children.whereType<IsometricRenderable>(), CameraComponent.currentCamera!.viewfinder.position, CameraComponent.currentCamera!.viewport.size);
  }
  //calculate the grid position from a world position
  @override
  Vector2 toGridPos(Vector2 worldPos) {
    Vector2 adjustedPos =
        worldPos - Vector2(level.position.x, level.position.y);
    return worldToTileIsometric(
          adjustedPos -
              Vector2(level.position.x + (level.width / 2), level.position.y),
        ) +
        Vector2(1, 1);
  }
  // Convert world position to isometric tile coordinates used in toGridPos
  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX =
        (worldPos.x / (tilesize.x / 2) + worldPos.y / (tilesize.z / 2)) / 2;
    final tileY =
        (worldPos.y / (tilesize.z / 2) - worldPos.x / (tilesize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }
  //calculate the world position from a grid position
  @override
  Vector2 toWorldPos(Vector2 gridPos, [double z = 0]) {
    final localPoint = Vector2(
      (gridPos.x - gridPos.y) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position
    final mapOriginOffset = Vector2(
      level.position.x + (level.width / 2),
      level.position.y,
    );
    //apply vertical movement for different layers according to z-index
    final layerOffset = Vector2(0, z * tilesize.z/32);//works for now as each tile is 32 pixels high in the tileset
    return localPoint + mapOriginOffset + layerOffset;
  }
// Convert orthogonal tile coordinates to isometric world coordinates.todo review if we need it as it does the same as toWorldPos
  Vector2 isometricToOrthogonal(Vector2 isometricPoint) {
    final halfTileW = tilesize.x / 2;
    final halfTileH = tilesize.z / 2;

    final worldX = (isometricPoint.y / halfTileH + isometricPoint.x / halfTileW) / 2;
    final worldY = (isometricPoint.y / halfTileH - isometricPoint.x / halfTileW) / 2;

    return Vector2(worldX, worldY);
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
      assert(value.isRectangle, 'Only rectangle objects are supported in the Collisions layer.');

      Vector2 gridObjectPos = toGridPos(value.position);

      if(Rect.fromPoints(gridObjectPos.toOffset(), gridObjectPos.toOffset() + (value.size..divide(tilesize.xz)).toOffset()).contains(gridPos.toOffset())){
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
            return TileSelectionResult(Vector3(gridPos.x, gridPos.y, i.toDouble()), gid);
          }
        }
      }
    }

    // If we looped through all layers and found nothing, return null.
    return null;
  }

}
