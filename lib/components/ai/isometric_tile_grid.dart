import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';

class IsometricTileGrid extends TileGrid{
  IsometricTileGrid(super.width, super.height, super.tileSize, super.collisionLayer, super.level);


  @override
  TileType getTileTypeAt(Vector2 worldPos) {
    if (collisionLayer == null) return TileType.air;

    for (final obj in collisionLayer!.objects) {

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
        (orthoPos.x - orthoPos.y) * 1.0,
        (orthoPos.x + orthoPos.y) * 0.5
    );
  }

  Offset _applyOffsetIsometric(Vector2 pos, Vector2 offset){
    Vector2 gridPos = level.toGridPos(pos) + Vector2(offset.x / tileSize.y, offset.y / tileSize.y);


    Vector2 offsetWorldPos = level.toWorldPos(gridPos);

    return offsetWorldPos.toOffset();
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

    canvas.translate(level.level.width / 2, 0);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        TileType val = grid[x][y];
        if (val != TileType.air) {
          Vector2 worldPos = level.toWorldPos(Vector2(x.toDouble(), y.toDouble()));
          Vector2 halfTile = tileSize / 2;

          List<Offset> diamond = [
            (worldPos + Vector2(0, -halfTile.y)).toOffset(),
            (worldPos + Vector2(halfTile.x, 0)).toOffset(),
            (worldPos + Vector2(0, halfTile.y)).toOffset(),
            (worldPos + Vector2(-halfTile.x, 0)).toOffset(),
          ];

          canvas.drawVertices(
              Vertices(VertexMode.triangleFan, diamond),
              BlendMode.screen,
              Paint()..color = Colors.green
          );
        }
      }
    }

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