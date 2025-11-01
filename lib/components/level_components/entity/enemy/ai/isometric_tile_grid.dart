import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Chunk;
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/level_components/entity/enemy/ai/tile_grid.dart';

import '../../../../../core/level/rendering/chunk.dart';
import '../../../../../util/isometric_utils.dart';

class IsometricTileGrid extends TileGrid {
  List<Vertices> vertices = [];

  IsometricTileGrid(
    super.width,
    super.height,
    super.tileSize,
    super.collisionLayer,
    super.level,
  );

  @override
  TileType getTileTypeAt(Vector2 worldPos) {
    if (collisionLayer == null) return TileType.air;

    for (final obj in collisionLayer!.objects) {
      // Convert the rectangular Tiled object into a list of isometric vertices
      // and check if the world position is inside this polygon.
      if (isPointInVertices(toVertices(obj), worldPos.toOffset())) {
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
    final Vector2 topLeft = obj.position;
    final Vector2 topRight = obj.position + Vector2(obj.size.x, 0);
    final Vector2 bottomLeft = obj.position + Vector2(0, obj.size.y);
    final Vector2 bottomRight = obj.position + obj.size;

    // Convert each corner to isometric space
    final Offset isoTopLeft = _orthogonalToIsometric(topLeft).toOffset();
    final Offset isoTopRight = _orthogonalToIsometric(topRight).toOffset();
    final Offset isoBottomLeft = _orthogonalToIsometric(bottomLeft).toOffset();
    final Offset isoBottomRight = _orthogonalToIsometric(bottomRight).toOffset();

    return [isoTopLeft, isoTopRight, isoBottomRight, isoBottomLeft];
  }

  // Converts orthogonal (grid) coordinates to isometric world coordinates.
  Vector2 _orthogonalToIsometric(Vector2 orthoPos) => Vector2(
      ((orthoPos.x - orthoPos.y) * 1.0),
      (orthoPos.x + orthoPos.y) * 0.5 + 1,
    );

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
          (point.dx <
              (vertices[j].dx - vertices[i].dx) *
                      (point.dy - vertices[i].dy) /
                      (vertices[j].dy - vertices[i].dy) +
                  vertices[i].dx)) {
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

    canvas.translate(Chunk.worldSize.x / 2, 0); // Center the grid horizontally

    if (collisionLayer != null) {
      for (final obj in collisionLayer!.objects) {
        final List<Offset> objVertices = toVertices(obj);
        canvas.drawVertices(
          Vertices(VertexMode.triangleFan, objVertices),
          BlendMode
              .screen, //Use a blend mode that makes overlapping shapes more visible
          Paint()..color = Colors.blue,
        );
      }
    }

    canvas.restore();
  }

  void renderTileHighlight(Canvas canvas, Vector2 gridPos) {
    // Convert the selected tile's grid coordinates into its center position in the isometric world.
    final Vector2 worldPos = toWorldPos(Vector3(gridPos.x, gridPos.y, 0));
    final Vector2 halfTile = tileSize / 2;

    // Define the four vertices of the isometric diamond for the tile.
    final List<Offset> diamond = [
      (worldPos + Vector2(0, -halfTile.y)).toOffset(), // Top center
      (worldPos + Vector2(halfTile.x, 0)).toOffset(), // Middle right
      (worldPos + Vector2(0, halfTile.y)).toOffset(), // Bottom center
      (worldPos + Vector2(-halfTile.x, 0)).toOffset(), // Middle left
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
}
