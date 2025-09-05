import 'dart:ui';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/isometric_tile_grid.dart';
import 'package:mpg_achievements_app/components/level/level.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'isometricRenderable.dart';
import 'isometricTiledLevel.dart';

class IsometricLevel extends Level {


  // Example isometric tile size (width, height)
  IsometricLevel({required super.levelName, required super.player, required super.tileSize});

  @override
  Future<void> onLoad() async {
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
    return IsometricTiledLevel((await TiledComponent.load(filename, destTilesize)).tileMap);
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
  void renderFromCamera(Canvas canvas) {
    assert(CameraComponent.currentCamera != null);
    super.renderTree(canvas);

    if(level is! IsometricTiledLevel) return;

    for (final child in children.where((element) => element is! IsometricRenderable && element != level)) {
      child.renderTree(canvas);
    }

    (level as IsometricTiledLevel).renderComponentsInTree(canvas, children.whereType<IsometricRenderable>());
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
      (gridPos.x + gridPos.y) * (tileSize.y),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position
    final mapOriginOffset = Vector2(
      level.position.x + (level.width / 2),
      level.position.y,
    );
    return localPoint + mapOriginOffset;
  }

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
}
