import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import '../level/game_world.dart';

class TileGrid extends Component {
  int width;
  int height;

  Vector2 tileSize;
  GameWorld level;

  List<List<TileType>> grid = [];
  List<List<bool>> highlightedSpots = [];

  ObjectGroup? collisionLayer;

  TileGrid(this.width, this.height, this.tileSize, this.collisionLayer, this.level) {
    grid = List.generate(
      width,
      (_) => List.filled(height, TileType.air),
    ); //fills the 2d grid list with false
    highlightedSpots = List.generate(
      width,
      (_) => List.filled(height, false),
    ); //fills the 2d grid list with false

    addCollisions();

  }

  void addCollisions(){
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {

        grid[x][y] = getTileTypeAt(
          level.toWorldPos(Vector2(x.toDouble(), y.toDouble())),
        );
      }
    }
  }

  ///returns the val at the given pos
  TileType valAt(Vector2 pos) {
    if (isInBounds(pos)) {
      return grid[pos.x.toInt()][pos.y.toInt()];
    } else {
      return TileType.solid;
    }
  }

  ///sets the val at the given pos
  void setVal(Vector2 pos, [TileType val = TileType.solid]) {
    if (isInBounds(pos)) grid[pos.x.toInt()][pos.y.toInt()] = val;
  }

  bool isBlocked(Vector2 gridPos) => valAt(gridPos) == TileType.solid;

  bool isFree(Vector2 gridPos) => valAt(gridPos) != TileType.solid;

  bool isInBounds(Vector2 gridPos) =>
      !(gridPos.x < 0 ||
          gridPos.y < 0 ||
          gridPos.x >= width ||
          gridPos.y >= height);

  void setAtWorldPos(Vector2 worldPos, [TileType val = TileType.solid]) {
    Vector2 gridPos = (worldPos..divide(tileSize))..floor();

    setVal(gridPos, val);
  }

  @override
  void renderDebugMode(Canvas canvas) {
    renderDebugTiles(canvas);
    super.render(canvas);
  }
  
  void renderDebugTiles(Canvas canvas){

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        TileType val = grid[x][y];
        if(val != TileType.air) {
          canvas.drawRect(Rect.fromPoints(
              (Vector2(x.toDouble(), y.toDouble())..multiply(tileSize)).toOffset(),
              (Vector2(x.toDouble(), y.toDouble())..multiply(tileSize)).toOffset() +
                  Offset(tileSize.x - 2, tileSize.y - 2)), Paint()
            ..color = Colors.green);
        }

        bool highlighted = highlightedSpots[x][y];
        if (highlighted) {
          canvas.drawRect(
            Rect.fromPoints(
              (Vector2(x.toDouble(), y.toDouble())..multiply(tileSize)).toOffset(),
              (Vector2(x.toDouble(), y.toDouble())..multiply(tileSize)).toOffset() +
                  Offset(tileSize.x - 2, tileSize.y - 2),
            ),
            Paint()..color = Colors.red,
          );
        }
      }
    }
  }





  TileType getTileTypeAt(Vector2 worldPos) {
    if (collisionLayer == null) return TileType.air;

    for (final obj in collisionLayer!.objects) {

      final rect = Rect.fromLTWH(obj.x, obj.y, obj.width, obj.height);
      if (rect.contains(
        worldPos.toOffset() + Offset(tileSize.x / 2, tileSize.y / 2),
      )) {
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
}

enum TileType { solid, platform, ladder, air }
