import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class IsometricTileGrid extends TileGrid with HasGameReference<PixelAdventure> {
  IsometricTileGrid(super.width, super.height, super.tileSize, super.collisionLayer, super.level);


  @override
  TileType getTileTypeAt(Vector2 worldPos) {
    if (collisionLayer == null) return TileType.air;

    for (final obj in collisionLayer!.objects) {

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

  List<Vertices> vertices = [];

  List<Offset> toVertices(TiledObject obj) {
    Vector2 topLeft = obj.position;
    Vector2 topRight = obj.position + Vector2(obj.size.x, 0);
    Vector2 bottomLeft = obj.position + Vector2(0, obj.size.y);
    Vector2 bottomRight = obj.position + obj.size;

    Offset isoTopLeft = _orthogonalToIsometric(topLeft).toOffset();
    Offset isoTopRight = _orthogonalToIsometric(topRight).toOffset();
    Offset isoBottomLeft = _orthogonalToIsometric(bottomLeft).toOffset();
    Offset isoBottomRight = _orthogonalToIsometric(bottomRight).toOffset();


    return [isoTopLeft, isoTopRight, isoBottomRight, isoBottomLeft];
  }

  Vector2 _orthogonalToIsometric(Vector2 orthoPos) {
    return Vector2(
        ((orthoPos.x - orthoPos.y) * 1.0),
        (orthoPos.x + orthoPos.y) * 0.5 + 1
    );
  }

  bool isPointInVertices(List<Offset> vertices, Offset point) {

    bool inside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; j = i++) {
      if (((vertices[i].dy > point.dy) != (vertices[j].dy > point.dy)) &&
          (point.dx < (vertices[j].dx - vertices[i].dx) *
              (point.dy - vertices[i].dy) /
              (vertices[j].dy - vertices[i].dy) + vertices[i].dx)) {
        inside = !inside;
      }
    }

    return inside;
  }



  @override
  void renderDebugTiles(Canvas canvas) {
    canvas.save();

    canvas.translate(level.level.width / 2, 0); // Center the grid horizontally

    if (collisionLayer != null) {
      for (final obj in collisionLayer!.objects) {
        List<Offset> objVertices = toVertices(obj);
        canvas.drawVertices(
            Vertices(VertexMode.triangleFan, objVertices),
            BlendMode.screen,
            Paint()..color = Colors.blue
        );
      }
    }

    canvas.restore();
  }


}