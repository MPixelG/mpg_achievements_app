import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';

class IsometricTileGrid extends TileGrid{


  List<Vertices> vertices = [];


  IsometricTileGrid(super.width, super.height, super.tileSize, super.collisionLayer, super.level);


  @override
  TileType getTileTypeAt(Vector2 worldPos) {
    if (collisionLayer == null) return TileType.air;

    for (final obj in collisionLayer!.objects) {
      // Convert the rectangular Tiled object into a list of isometric vertices
      // and check if the world position is inside this polygon.
      if (isPointInVertices(toVertices(obj), worldPos.toOffset())) {
        print("not air at ${level.toGridPos(obj.position)}");
        return switch (obj.class_) {
          "" => TileType.solid,
          "Ladder" => TileType.ladder,
          "Platform" => TileType.platform,
          _ => TileType.solid,
        };
      }
    }
    return TileType.air;
  }

  // Converts a rectangular [TiledObject] into a list of [Offset] points
  // representing its vertices in isometric space.
  //
  // The method calculates the four corners of the object in orthogonal (grid) space
  // and then transforms each corner into isometric world space.
  //
  // Returns a list of four [Offset]s representing the isometric diamond shape.

  List<Offset> toVertices(TiledObject obj) {
    Vector2 topLeft = obj.position;
    Vector2 topRight = obj.position + Vector2(obj.size.x, 0);
    Vector2 bottomLeft = obj.position + Vector2(0, obj.size.y);
    Vector2 bottomRight = obj.position + obj.size;

    // Convert each corner to isometric space
    Offset isoTopLeft = _orthogonalToIsometric(topLeft).toOffset();
    Offset isoTopRight = _orthogonalToIsometric(topRight).toOffset();
    Offset isoBottomLeft = _orthogonalToIsometric(bottomLeft).toOffset();
    Offset isoBottomRight = _orthogonalToIsometric(bottomRight).toOffset();

    return [isoTopLeft, isoTopRight, isoBottomRight, isoBottomLeft];
  }
 // Converts orthogonal (grid) coordinates to isometric world coordinates.
  Vector2 _orthogonalToIsometric(Vector2 orthoPos) {
    return Vector2(
        ((orthoPos.x - orthoPos.y) * 1.0),
        (orthoPos.x + orthoPos.y) * 0.5 + 1
    );
  }

  /*This function takes a starting position (pos) in world coordinates and applies an offset to it as if that offset were happening on the flat, 2D grid, before converting the final result back into isometric world coordinates.
  It's a way to move an object by a certain amount in the "logical" grid space (e.g., "move 16 pixels right and 8 pixels down on the grid") and get the correct corresponding position in the "visual" isometric world space.*/


  Offset _applyOffsetIsometric(Vector2 pos, Vector2 offset){

    // Step 1: Convert the current world position into grid coordinates.
    // 'level.toGridPos(pos)' translates the isometric world coordinates (e.g., where something
    // is drawn on the screen) into its logical grid cell coordinates (e.g., tile [5, 3]).
    Vector2 gridPos = level.toGridPos(pos) + Vector2(offset.x / tileSize.y, offset.y / tileSize.y);

    // Step 2: Apply the offset in grid space.
    // The 'offset' is treated as a movement along the orthogonal grid axes.
    // We divide the offset components by the tile's height (tileSize.y) because in many
    // isometric setups, the vertical grid spacing corresponds to the tile height.
    // This converts the pixel offset into a tile-based offset.
    // For example, an offset of (0, 16) with a tileSize.y of 16 would mean "move down by one full tile".

    Vector2 offsetWorldPos = level.toWorldPos(gridPos);

    return offsetWorldPos.toOffset();
  }


  // Ray-casting algorithm to determine if a point is inside a polygon defined by [vertices].
  // The algorithm works by counting how many times a ray starting from the point intersects
  // the edges of the polygon. If the count is odd, the point is inside; if even, it's outside.

  bool isPointInVertices(List<Offset> vertices, Offset point) {

    bool inside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; j = i++) {
      // Check if the point is within the y-bounds of the edge
      if (((vertices[i].dy > point.dy) != (vertices[j].dy > point.dy)) &&
          // Check if the point is to the left of the edge
          (point.dx < (vertices[j].dx - vertices[i].dx) *
              (point.dy - vertices[i].dy) /
              (vertices[j].dy - vertices[i].dy) + vertices[i].dx)) {
        // Toggle the inside flag
        inside = !inside;
      }
    }

    return inside;
  }

  // Renders a visual representation of the grid and collision objects for debugging.
  //
  // This method should be called from the game's `render` loop when debug mode is active.
  // It draws:
  // 1. Green diamonds for every logical tile in the `grid` that is not `TileType.air`.
  // 2. Blue polygons for the actual collision shapes from the `collisionLayer`.
  //
  // [canvas]: The canvas to draw on.

  @override
  void renderDebugTiles(Canvas canvas) {
    canvas.save();

    // The isometric projection is often centered on the map's width.
    // This translation ensures the debug rendering aligns with the visual map.
    canvas.translate(level.level.width / 2, 0);
    //Render the logical grid tiles.
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        TileType val = grid[x][y];
        if (val != TileType.air) {
          Vector2 worldPos = level.toWorldPos(Vector2(x.toDouble(), y.toDouble()));
          Vector2 halfTile = tileSize / 2;
          // Create a diamond shape for the isometric tile
          List<Offset> diamond = [
            (worldPos + Vector2(0, -halfTile.y)).toOffset(),// top point
            (worldPos + Vector2(halfTile.x, 0)).toOffset(),// right point
            (worldPos + Vector2(0, halfTile.y)).toOffset(),// bottom point
            (worldPos + Vector2(-halfTile.x, 0)).toOffset(),// left point
          ];
          // Draw the diamond shape
          canvas.drawVertices(
              Vertices(VertexMode.triangleFan, diamond),
              BlendMode.screen,
              Paint()..color = Colors.green
          );
        }
      }
    }
    // Render the actual collision objects from the Tiled map.
    if (collisionLayer != null) {
      for (final obj in collisionLayer!.objects) {
        List<Offset> objVertices = toVertices(obj);
        canvas.drawVertices(
            Vertices(VertexMode.triangleFan, objVertices),
            BlendMode.screen, //Use a blend mode that makes overlapping shapes more visible
            Paint()..color = Colors.blue
        );
      }
    }

    canvas.restore();
  }

  void renderTileHighlight(Canvas canvas, Vector2 gridPos) {
    // Save the canvas state so our transformations don't affect other rendering.
    canvas.save();
    // Translate to center the isometric map on the canvas.
    // debug rendering to ensure the highlight aligns with the map.
    canvas.translate(level.level.width / 2, 0);

    // Convert the selected tile's grid coordinates into its center position in the isometric world.
    Vector2 worldPos = level.toWorldPos(gridPos);
    Vector2 halfTile = tileSize / 2;

    // Define the four vertices of the isometric diamond for the tile.
    List<Offset> diamond = [
      (worldPos + Vector2(0, -halfTile.y)).toOffset(),   // Top center
      (worldPos + Vector2(halfTile.x, 0)).toOffset(),   // Middle right
      (worldPos + Vector2(0, halfTile.y)).toOffset(),   // Bottom center
      (worldPos + Vector2(-halfTile.x, 0)).toOffset(),  // Middle left
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

    // Restore the canvas to its previous state.
    canvas.restore();
  }


}