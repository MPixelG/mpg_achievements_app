import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:mpg_achievements_app/components/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'highlighted_tile.dart';
import 'isometricRenderable.dart';
import 'isometricTiledComponent.dart';

class TileSelectionResult {
  final Vector2 gridPosition;
  final int layerIndex;
  final Gid tileGid; // The Gid object from Tiled, which contains the tile ID

  TileSelectionResult(this.gridPosition, this.layerIndex, this.tileGid);
}


class IsometricWorld extends GameWorld {

  late IsometricTileGrid tileGrid;
  Vector2? selectedTile;
  TileHighlightRenderable? highlightedTile;

  // Example isometric tile size (width, height)
  IsometricWorld({required super.levelName, required super.tileSize});

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
      tileSize,//setting the tile size to match the isometric tile dimensions
      collisionLayer,
      this,
    );
  }

  @override
  Future<TiledComponent> createTiledLevel(String filename, Vector2 destTilesize) async{
    return IsometricTiledComponent((await TiledComponent.load(filename, destTilesize)).tileMap);
  }

  //highlight the selected tile
  @override
  void render(Canvas canvas) {
    // This renders the Tiled map and all other components first.
    super.render(canvas);

    // After the map is drawn, we check if a tile has been selected.
    // If so, we call the highlight method on our grid instance.
    tileGrid.renderTileHighlight(canvas, selectedTile!);
    }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    //final Vector2 screenPositionTap = event.localPosition; //screen position of the tap
    //final Vector2 worldPositionTap = level.toLocal(screenPositionTap);
    //selectedTile = toGridPos(worldPositionTap)..floor();
    final screenPositionTap = event.localPosition;
    final worldPositionTap = level.toLocal(screenPositionTap);
    Vector2? selectedTile = toGridPos(worldPositionTap)..floor();

    // Use the function to find the top-most tile.
    final selectionResult = getTopmostTileAtGridPos(selectedTile);

    // Remove the old highlight.
    highlightedTile?.removeFromParent();

    if (selectionResult != null) {
      // A tile was successfully selected!

      // Create the highlight with both grid position and layer index.
      highlightedTile = TileHighlightRenderable(
        selectionResult.gridPosition,
        selectionResult.layerIndex,
      );

      // Position the highlight using the layer-aware toWorldPos.
      highlightedTile!.position = toWorldPos(
        selectionResult.gridPosition,
        layerIndex: selectionResult.layerIndex,
      ) + Vector2(0, -tileSize.y / 2); // Adjust for isometric tile height



      add(highlightedTile!);
      print("Selected tile at ${selectionResult
          .gridPosition} on layer ${selectionResult.layerIndex}");
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

    (level as IsometricTiledComponent).renderComponentsInTree(canvas, children.whereType<IsometricRenderable>());
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
        (worldPos.x / (tileSize.x / 2) + worldPos.y / (tileSize.y / 2)) / 2;
    final tileY =
        (worldPos.y / (tileSize.y / 2) - worldPos.x / (tileSize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }
  //calculate the world position from a grid position
  @override
  Vector2 toWorldPos(Vector2 gridPos, {int layerIndex = 0}) {
    final localPoint = Vector2(
      (gridPos.x - gridPos.y) * (tileSize.x / 2),
      (gridPos.x + gridPos.y) * (tileSize.y/2),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position
    final mapOriginOffset = Vector2(
      level.position.x + (level.width / 2),
      level.position.y,
    );
    //apply vertical movement for different layers according to z-index
    final layerOffset = Vector2(0, layerIndex * tileSize.y/32);//works for now as each tile is 32 pixels high in the tileset
    return localPoint + mapOriginOffset + layerOffset;
  }
// Convert orthogonal tile coordinates to isometric world coordinates.todo review if we need it as it does the same as toWorldPos
  Vector2 isometricToOrthogonal(Vector2 isometricPoint) {
    final halfTileW = tileSize.x / 2;
    final halfTileH = tileSize.y / 2;

    final worldX = (isometricPoint.y / halfTileH + isometricPoint.x / halfTileW) / 2;
    final worldY = (isometricPoint.y / halfTileH - isometricPoint.x / halfTileW) / 2;

    return Vector2(worldX, worldY);
  }

  @override
  bool checkCollisionAt(Vector2 gridPos) {
    final int x = gridPos.x.floor();
    final int y = gridPos.y.floor();
    // Access the 'Collisions' layer from the Tiled map
    final layer = level.tileMap.map.layerByName('Collisions') as ObjectGroup?;
    if (layer == null) {
      return false;
    }
    // Check boundaries of the tile data if outside return true for collision

    for (var value in layer.objects) {
      assert(value.isRectangle, 'Only rectangle objects are supported in the Collisions layer.');

      Vector2 gridObjectPos = toGridPos(value.position);

      if(Rect.fromPoints(gridObjectPos.toOffset(), gridObjectPos.toOffset() + (value.size..divide(Vector2.all(tileSize.x))).toOffset()).contains(gridPos.toOffset())){
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
            return TileSelectionResult(gridPos, i, gid);
          }
        }
      }
    }

    // If we looped through all layers and found nothing, return null.
    return null;
  }

}
