import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:flame_tiled/flame_tiled.dart';

class IsometricLevel extends Level {


  // Example isometric tile size (width, height)
  IsometricLevel({required super.levelName, required super.player, required tileSize});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    //find the collision layer
    final collisionLayer = level.tileMap.getLayer<ObjectGroup>('Collisions');
    tileGrid = IsometricTileGrid(
      level.tileMap.map.width,
      level.tileMap.map.height,
      //setting the tile size to match the isometric tile dimensions
      tileSize,
      collisionLayer,
      this,
    );
  }

  //highlight the selected tile
  @override
  void render(Canvas canvas) {
    // This renders the Tiled map and all other components first.
    super.render(canvas);

    // After the map is drawn, we check if a tile has been selected.
    if (game.level.selectedTile != null) {
      // If so, we call the highlight method on our grid instance.
      tileGrid.renderTileHighlight(canvas, selectedTile!);
    }
  }

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

  Vector2 worldToTileIsometric(Vector2 worldPos) {
    final tileX =
        (worldPos.x / (tileSize.x / 2) + worldPos.y / (tileSize.y / 2)) / 2;
    final tileY =
        (worldPos.y / (tileSize.y / 2) - worldPos.x / (tileSize.x / 2)) / 2;

    return Vector2(tileX, tileY);
  }

  @override
  Vector2 toWorldPos(Vector2 gridPos) {
    final localPoint = Vector2(
      (gridPos.x - gridPos.y) * (tileSize.x / 2),
      (gridPos.x + gridPos.y) * (tileSize.y / 2),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position
    final mapOriginOffset = Vector2(
      level.position.x + (level.width / 2),
      level.position.y,
    );
    return localPoint + mapOriginOffset;
  }

  @override
  bool checkCollisionAt(Vector2 worldPoint, Vector2 center, Vector2 size) {
    final gridCoords = toGridPos(worldPoint);
    final int x = gridCoords.x.floor();
    final int y = gridCoords.y.floor();
    // Access the 'Collisions' layer from the Tiled map
    final layer = level.tileMap.map.layerByName('Collisions') as TileLayer?;
    if (layer == null) {
      return false;
    }
    // Check boundaries of the tile data if outside return true for collision
    if (x < 0 ||
        y < 0 ||
        y >= layer.tileData!.length ||
        x >= layer.tileData![y].length) {
      return true;
    }
    // Check if the tile at the calculated grid position is non-null (indicating a collision)
    final gid = layer.tileData?[y][x];
    if (gid == null || gid.tile == 0) {
      // No tile means no collision
      return false;
    }
    final tile = level.tileMap.map.tileByGid(gid.tile);
    // Check for custom property 'collidable' in the tile's properties
    final isCollidable = tile?.properties.getValue('collidable') ?? false;
    return isCollidable;
  }

  @override
  RectangleHitbox createHitbox({Vector2? position, Vector2? size}) {
    return RectangleHitbox(position: position, size: size);
  }
}
