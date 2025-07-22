import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/ai/pathfinder.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ExperimentalPathfinder{

  late RectangleHitbox pathfindingHitbox;
  Vector2 endPos = Vector2.zero();
  bool active = false;

  void setEndPos(Vector2 newEndPos, [val = true]){
    endPos = newEndPos;
    active = val;
  }
}

enum PathfindingAction {
  walk, jump, fall, climbUp, climbDown
}


class POIGenerator {
  Level level;

  late TileGrid grid;

  late List<POINode> nodes;

  POIGenerator(this.level){
    grid = TileGrid((level.level.width / 32).toInt(), (level.level.height / 32).toInt(), 32, level.level.tileMap.getLayer("Collisions") as ObjectGroup);
    level.add(grid);

    nodes = [];
    addAllNodes();
  }

  void onClick(TapDownEvent event){
    Vector2 gridPos = (level.mousePos / 32)..floor()..round();

    POINode? node = getNodeAt(gridPos);

    if(node != null){

      print(node);

    }

    print("clicked at " + gridPos.toString());
  }


  void addAllNodes(){

    int x = 0;
    grid.grid.forEach((element) {
      int y = 0;
      element.forEach((element) {
        if(element != TileType.solid) {
          nodes.add(POINode(Vector2(x.toDouble(), y.toDouble())));
        }
        y++;
      });

      x++;
    });


    addWalkableNodeConnections();
    addFallNodeConnections();
  }


  void addWalkableNodeConnections(){
    nodes.forEach((node) {

      if(isOnGround(node.position)){
        if(isOnGround(node.position + Vector2(1, 0))){
          POINode? other = getNodeAt(node.position + Vector2(1, 0));
          if(other != null){
            node.addConnection(POINodeConnection(other, PathfindingAction.walk, 0.5));
          }
        }

        if(isOnGround(node.position + Vector2(-1, 0))){
          POINode? other = getNodeAt(node.position + Vector2(-1, 0));
          if(other != null) {
            node.addConnection(POINodeConnection(
                getNodeAt(node.position + Vector2(-1, 0))!,
                PathfindingAction.walk, 0.5));
          }
        }
      }
    });
  }

  void addFallNodeConnections(){

    nodes.forEach((node) {
      if(!isOnGround(node.position)){

        Vector2 posDownLeft = node.position + Vector2(-1, 1);
        Vector2 posDown = node.position + Vector2(0, 1);
        Vector2 posDownRight = node.position + Vector2(1, 1);


        POINode? otherLeft;
        if(grid.isFree(posDownLeft)) otherLeft = getNodeAt(posDownLeft);

        POINode? otherDown;
        if(grid.isFree(posDown)) otherDown = getNodeAt(posDown);

        POINode? otherRight;
        if(grid.isFree(posDownRight)) otherRight = getNodeAt(posDownRight);


        if (otherLeft != null) {
          node.addConnection(POINodeConnection(
            getNodeAt(posDownLeft)!,
            PathfindingAction.fall, 0.3));
        }
        if (otherDown != null) {
          node.addConnection(POINodeConnection(
              getNodeAt(posDown)!,
              PathfindingAction.fall, 0.3));
        }
        if (otherRight != null) {
          node.addConnection(POINodeConnection(
              getNodeAt(posDownRight)!,
              PathfindingAction.fall, 0.3));
        }
      }
    });

  }


  bool isOnGround(Vector2 pos) {
    TileType tileBelow = grid.valAt(pos + Vector2(0, 1));
    bool isFieldFree = grid.isFree(pos);

    return (tileBelow == TileType.solid || tileBelow == TileType.ladder || tileBelow == TileType.platform) && isFieldFree;
  }

    POINode? getNodeAt(Vector2 pos) {
      try {
        return nodes.firstWhere((element) => element.position == pos);
      } on StateError {
        return null;
      }

    }
  }



class POINode{
  List<POINodeConnection>? connections = [];
  Vector2 position;

  POINode(this.position, [this.connections]){
    connections ??= []; //if the connections are null, we create an empty list
  }

  void addConnection(POINodeConnection connection) => connections!.add(connection);


  @override
  String toString() {

    String out = "$position - {${connections.toString()}}";

    return out;
  }

}


class POINodeConnection {
  POINode target;
  PathfindingAction action;
  double cost;
  POINodeConnection(this.target, this.action, this.cost);

  @override
  String toString() {
    return "${action.name} -> ${target.position.toString()}";
  }

}