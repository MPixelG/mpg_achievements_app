import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';

class Pathfinder{
  late double tileSize;
  late TileGrid grid;

  Vector2 toWorldPos(Vector2 gridPos) => gridPos * tileSize;
  Vector2 toGridPos(Vector2 worldPos) {
    final divided = worldPos / tileSize;
    return Vector2(divided.x.floor().toDouble(), divided.y.floor().toDouble());
  }

  Pathfinder(this.grid, this.tileSize);


  List<Vector2>? findPath(Vector2 startGridPos, Vector2 endGridPos) {
    Map<String, Node> openSet = {};
    Set<String> closedSet = {};

    Node startNode = Node(startGridPos);
    startNode.estimatedDistanceToEnd = calculateHCost(startGridPos, endGridPos);

    String startKey = nodeKey(startNode);
    openSet[startKey] = startNode;

    while (openSet.isNotEmpty) {
      String currentKey = openSet.keys.reduce((a, b) =>
      openSet[a]!.totalCost < openSet[b]!.totalCost ? a : b);

      Node current = openSet.remove(currentKey)!;
      closedSet.add(currentKey);


      if (current.gridPos == endGridPos) {
        return reconstructPath(current);
      }

      List<Action> possibleActions = getPossibleActions(current);

      for (Action action in possibleActions) {
        String neighborKey = "${action.endPos.x}_${action.endPos.y}";

        print("possible action at ${action.startPos.toString()}: " + action.types.toString() + " to " + action.endPos.toString());


        if (closedSet.contains(neighborKey)) continue;

        Node neighbor = Node(action.endPos);
        neighbor.parent = current;
        neighbor.actionUsed = action;
        neighbor.distanceToStart = current.distanceToStart + action.cost;
        neighbor.estimatedDistanceToEnd = calculateHCost(action.endPos, endGridPos);

        if (!openSet.containsKey(neighborKey) ||
            neighbor.distanceToStart < openSet[neighborKey]!.distanceToStart) {
          openSet[neighborKey] = neighbor;
        }
      }
    }

    return null;
  }

  double calculateEstimatedDistanceToEnd(Vector2 currentPos, Vector2 endPos) {
    return (currentPos.x - endPos.x).abs() + (currentPos.y - endPos.y).abs();
  }


  List<Action> getPossibleActions(Node current){
    List<Action> actions = [];
    Vector2 pos = current.gridPos;




    if(isOnGround(pos)){
      //walking

      Vector2 leftPos = pos + Vector2(-1, 0);
      if(grid.isFree(leftPos)) actions.add(Action({ActionType.walk}, pos, leftPos, 1.0));

      Vector2 rightPos = pos + Vector2(1, 0);
      if(grid.isFree(rightPos)) actions.add(Action({ActionType.walk}, pos, rightPos, 1.0));

      actions.addAll(generateJumpActions(pos));


    } else{
      List<Vector2> targets = calculateFallTargets(pos);
      for(Vector2 target in targets) {
        Action action = Action({ActionType.fall}, pos, target, target.y);
        actions.add(action);
      }
    }

    return actions;
  }

  List<Vector2> calculateFallTargets(Vector2 startPos) {
    List<Vector2> targets = [];
    for (int y = startPos.y.toInt() + 1; y < startPos.y + 16; y++) {
      Vector2 testPos = Vector2(startPos.x, y.toDouble());

      targets.add(Vector2(startPos.x, y.toDouble()));
      targets.add(Vector2(startPos.x-1, y.toDouble()));
      targets.add(Vector2(startPos.x+1, y.toDouble()));
      if (grid.isBlocked(testPos + Vector2(0, 1))) {
        break;
      }
    }

    return targets;
  }


  List<Action> generateJumpActions(Vector2 startPos) {
    List<Action> jumpActions = [];

    List<Vector2> jumpTargets = [
      Vector2(0, -3),
      Vector2(1, -3),
      Vector2(2, -3),
      Vector2(3, -3),
      Vector2(-1, -3),
      Vector2(-2, -3),
      Vector2(-3, -3),

    ];

    for (Vector2 jumpOffset in jumpTargets) {
      Vector2 targetPos = startPos + jumpOffset;

      if (isValidJump(startPos, targetPos)) {
        double jumpCost = 3.0;
        ActionType jumpType = jumpOffset.x > 0 ? ActionType.jump :
        jumpOffset.x < 0 ? ActionType.jump : ActionType.jump;

        jumpActions.add(Action({jumpType}, startPos, targetPos, jumpCost));
      }
    }

    return jumpActions;
  }

  bool isValidJump(Vector2 start, Vector2 end) {
    List<Vector2> jumpArc = calculateJumpArc(start, end);

    for (Vector2 point in jumpArc) {
      if (grid.isBlocked(point)) {
        return false;
      }
    }
    return true;
  }

  List<Vector2> calculateJumpArc(Vector2 start, Vector2 end) {
    List<Vector2> arc = [];

    double dx = end.x - start.x;
    double dy = end.y - start.y;

    int steps = (dx.abs() * 2).toInt();
    if (steps == 0) steps = (dy.abs() * 2).toInt().clamp(1, 10);

    for (int i = 0; i <= steps; i++) {
      double t = steps > 0 ? i / steps : 0.0;
      double x = start.x + dx * t;
      double y = start.y + dy * t - 4 * t * (1 - t) * 2;

      arc.add(Vector2(x.round().toDouble(), y.round().toDouble()));
    }

    return arc;
  }


  double calculateHCost(Vector2 from, Vector2 to) {
    double dx = (to.x - from.x).abs();
    double dy = to.y - from.y;

    double cost = dx;

    if (dy > 0) {
      cost += dy * 0.5;
    } else {
      cost += dy.abs() * 3.0;
    }

    return cost;
  }


  String nodeKey(Node node) => "${node.gridPos.x}_${node.gridPos.y}";

  List<Vector2> reconstructPath(Node endNode) {
    List<Vector2> path = [];
    Node? current = endNode;

    while (current != null) {
      path.add(current.gridPos );
      current = current.parent;
    }

    return path.reversed.toList();//so that we go from start to end, not from end to start
  }


  bool isOnGround(Vector2 pos) => grid.valAt(pos - Vector2(0, -1)); //if the block beneath is solid, it is on ground

}

enum  ActionType{
  walk, fall, jump, fallSideways
}

class Action{

  Set<ActionType> types;
  Vector2 startPos;
  Vector2 endPos;
  double cost;

  Action(this.types, this.startPos, this.endPos, this.cost);
}

class Node{

  Node? parent;

  double distanceToStart = 0;
  double estimatedDistanceToEnd = 0;

  double get totalCost => distanceToStart + estimatedDistanceToEnd;

  Vector2 gridPos;

  Action? actionUsed;



  Node(this.gridPos);


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Node && gridPos == other.gridPos;



  @override
  int get hashCode => gridPos.hashCode;
}

