import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

class TileGrid extends Component{

  int width;
  int height;

  double tileSize;

  List<List<bool>> grid = [];
  List<List<bool>> highlightedSpots = [];

  ObjectGroup? collisionLayer;


  TileGrid(this.width, this.height, this.tileSize, this.collisionLayer){
    grid = List.generate(width, (_) => List.filled(height, false)); //fills the 2d grid list with false
    highlightedSpots = List.generate(width, (_) => List.filled(height, false)); //fills the 2d grid list with false


    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {

        if(hasCollisionAt(Vector2(x.toDouble(), y.toDouble()) * tileSize)){
          grid[x][y] = true;
        }

      }
    }

  }
  ///returns the val at the given pos
  bool valAt(Vector2 pos) => isInBounds(pos) && grid[pos.x.toInt()][pos.y.toInt()];
  ///sets the val at the given pos
  void setVal(Vector2 pos, [bool val = true]){if(isInBounds(pos)) grid[pos.x.toInt()][pos.y.toInt()] = val;}


  bool isBlocked(Vector2 gridPos) => valAt(gridPos);
  bool isFree(Vector2 gridPos) => !valAt(gridPos);

  bool isInBounds(Vector2 gridPos) => !(gridPos.x < 0 || gridPos.y < 0 || gridPos.x >= width || gridPos.y >= height);


  void setAtWorldPos(Vector2 worldPos, [bool val = true]){
    Vector2 gridPos = (worldPos / tileSize)..floor();

    setVal(gridPos, val);
  }




  @override
  void render(Canvas canvas) {
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
       /* bool val = grid[x][y];
        if(val) {
          canvas.drawRect(Rect.fromPoints(
              (Vector2(x.toDouble(), y.toDouble()) * (tileSize)).toOffset(),
              (Vector2(x.toDouble(), y.toDouble()) * (tileSize)).toOffset() +
                  Offset(tileSize - 2, tileSize - 2)), Paint()
            ..color = Colors.green);
        }*/

        bool highlighted = highlightedSpots[x][y];
        if(highlighted){
          canvas.drawRect(Rect.fromPoints(
              (Vector2(x.toDouble(), y.toDouble()) * (tileSize)).toOffset(),
              (Vector2(x.toDouble(), y.toDouble()) * (tileSize)).toOffset() +
                  Offset(tileSize - 2, tileSize - 2)), Paint()
            ..color = Colors.red);
        }


      }
    }

    super.render(canvas);
  }

  bool hasCollisionAt(Vector2 worldPos) {
    if (collisionLayer == null) return false;

    for (final obj in collisionLayer!.objects) {
      final rect = Rect.fromLTWH(obj.x, obj.y, obj.width, obj.height);
      if (rect.contains(worldPos.toOffset())) {
        return true;
      }
    }
    return false;
  }

}