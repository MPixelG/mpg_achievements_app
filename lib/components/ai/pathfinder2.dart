import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/geometry.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ExperimentalPathfinder {
  late RectangleHitbox pathfindingHitbox;
  Vector2 endPos = Vector2.zero();
  bool active = false;

  void setEndPos(Vector2 newEndPos, [val = true]) {
    endPos = newEndPos;
    active = val;
  }
}

enum PathfindingAction { walk, jump, fall, climbUp, climbDown }

class POIGenerator extends Component with HasGameReference<PixelAdventure>{
  Level level;

  late TileGrid grid;

  late List<POINode> nodes;

  POIGenerator(this.level) {
    grid = TileGrid(
      (level.level.width / 32).toInt(),
      (level.level.height / 32).toInt(),
      32,
      level.level.tileMap.getLayer("Collisions") as ObjectGroup,
    );
    level.add(grid);

    nodes = [];
    addAllNodes();
  }

  Vector2 lastClickPoint = Vector2(0, 0);

  List<POINode>? path;

  void onClick(TapDownEvent event) {
    Vector2 gridPos = (level.mousePos / 32)
      ..floor()
      ..round();

    POINode? node = getNodeAt(gridPos);

    if (node != null) {
      print(node);
    }


    path = getPathTo(lastClickPoint, gridPos);
    lastClickPoint = gridPos.clone();
  }

  void addAllNodes() {
    int x = 0;
    grid.grid.forEach((element) {
      int y = 0;
      element.forEach((element) {
        if (element != TileType.solid) {
          nodes.add(POINode(Vector2(x.toDouble(), y.toDouble())));
        }
        y++;
      });

      x++;
    });

    addWalkableNodeConnections();
    addFallNodeConnections();
    addJumpNodeConnections();
  }

  void addWalkableNodeConnections() {
    nodes.forEach((node) {
      if (isOnGround(node.position)) {
        if (grid.isFree(node.position + Vector2(1, 0))) {
          POINode? other = getNodeAt(node.position + Vector2(1, 0));
          if (other != null) {
            node.addConnection(
              POINodeConnection(other, PathfindingAction.walk, 0.5),
            );
          }
        }

        if (grid.isFree(node.position + Vector2(-1, 0))) {
          POINode? other = getNodeAt(node.position + Vector2(-1, 0));
          if (other != null) {
            node.addConnection(
              POINodeConnection(
                getNodeAt(node.position + Vector2(-1, 0))!,
                PathfindingAction.walk,
                0.5,
              ),
            );
          }
        }
      }
    });
  }
  void addFallNodeConnections() {
    nodes.forEach((node) {
      if (!isOnGround(node.position)) {
        Vector2 posDownLeft = node.position + Vector2(-1, 1);
        Vector2 posDown = node.position + Vector2(0, 1);
        Vector2 posDownRight = node.position + Vector2(1, 1);

        POINode? otherLeft;
        if (grid.isFree(posDownLeft)) otherLeft = getNodeAt(posDownLeft);

        POINode? otherDown;
        if (grid.isFree(posDown)) otherDown = getNodeAt(posDown);

        POINode? otherRight;
        if (grid.isFree(posDownRight)) otherRight = getNodeAt(posDownRight);

        if (otherLeft != null) {
          node.addConnection(
            POINodeConnection(
              getNodeAt(posDownLeft)!,
              PathfindingAction.fall,
              0.3,
            ),
          );
        }
        if (otherDown != null) {
          node.addConnection(
            POINodeConnection(getNodeAt(posDown)!, PathfindingAction.fall, 0.3),
          );
        }
        if (otherRight != null) {
          node.addConnection(
            POINodeConnection(
              getNodeAt(posDownRight)!,
              PathfindingAction.fall,
              0.3,
            ),
          );
        }
      }
    });
  }
  void addJumpNodeConnections() {
    nodes.forEach((node) {
      if (isOnGround(node.position)) {
        addJumpNodeInDirection(node, 0);
        addJumpNodeInDirection(node, 1);
        addJumpNodeInDirection(node, 2);
        addJumpNodeInDirection(node, -1);
        addJumpNodeInDirection(node, -2);
      }
    });
  }
  void addJumpNodeInDirection(POINode node, double differenceX) {
    int heightToCeiling = getHeightToNextCeiling(
      node.position,
      maxHeightToCheck: 2,
    );
    if (heightToCeiling > differenceX.abs()) {
      Vector2 jumpDestination =
          node.position + Vector2(differenceX, -heightToCeiling.toDouble());

      if (!hasClearPath(node.position, jumpDestination)) {
        print("didnt add bc theres no clear path");

        return;
      }

      POINode? nodeAtDestination = getNodeAt(jumpDestination);

      if (nodeAtDestination != null) {
        POINodeConnection connection = POINodeConnection(
          nodeAtDestination,
          PathfindingAction.jump,
          differenceX.abs() / 2 + 2,
        );
        node.addConnection(connection);
        print("added connection at ${node.position.toString()} to ${jumpDestination.toString()}");
      } else
        print("didnt add bc theres no node there");
    }
  }

  bool hasClearPath(Vector2 firstPos, Vector2 otherPos) {
    if (firstPos.distanceTo(otherPos) < 0.01) {
      return true;
    }

    PixelAdventure game = (level.game as PixelAdventure);

    Vector2 direction = (otherPos - firstPos).normalized();

    Ray2 ray = Ray2(origin: firstPos * 32, direction: direction);

    RaycastResult<ShapeHitbox>? result = game.collisionDetection.raycast(
      ray,
      maxDistance: firstPos.distanceTo(otherPos) * 32,
    );

    return result == null;
  }

  int getHeightToNextCeiling(Vector2 pos, {int maxHeightToCheck = 3}) {
    for (
      int currentHeightDifference = 0;
      currentHeightDifference <= maxHeightToCheck;
      currentHeightDifference++
    ) {
      if (grid.isBlocked(
        pos + Vector2(0, -currentHeightDifference.toDouble()),
      )) {
        return currentHeightDifference;
      }
    }
    return maxHeightToCheck;
  }

  bool isOnGround(Vector2 pos) {
    TileType tileBelow = grid.valAt(pos + Vector2(0, 1));
    bool isFieldFree = grid.isFree(pos);

    return (tileBelow == TileType.solid ||
            tileBelow == TileType.ladder ||
            tileBelow == TileType.platform) &&
        isFieldFree;
  }

  POINode? getNodeAt(Vector2 pos) {
    try {
      return nodes.firstWhere((element) => element.position == pos);
    } on StateError {
      return null;
    }
  }



  List<POINode>? getPathTo(Vector2 startPos, Vector2 endPos) {
    POINode? startNode = getNodeAt(startPos);
    POINode? endNode = getNodeAt(endPos);

    if (startNode == null || endNode == null) {
      print("Start- oder Endnode nicht gefunden");
      return null;
    }

    if (startNode == endNode) {
      return [startNode];
    }

    Set<PathfindingNode> openNodes = {};
    Set<PathfindingNode> closedNodes = {};
    Map<POINode, PathfindingNode> nodeMap = {};

    PathfindingNode startPathNode = PathfindingNode(
        startNode,
        0,
        getEstimatedDistanceToEnd(startNode.position, endNode.position)
    );
    openNodes.add(startPathNode);
    nodeMap[startNode] = startPathNode;

    while (openNodes.isNotEmpty) {
      PathfindingNode currentNode = openNodes.reduce(
              (a, b) => a.totalCost < b.totalCost ? a : b
      );

      if (currentNode.poiNode == endNode) {
        return reconstructPath(currentNode);
      }

      openNodes.remove(currentNode);
      closedNodes.add(currentNode);

      if (currentNode.poiNode.connections != null) {
        for (POINodeConnection connection in currentNode.poiNode.connections!) {
          POINode neighbor = connection.target;

          if (closedNodes.any((node) => node.poiNode == neighbor)) {
            continue;
          }

          double tentativeGScore = currentNode.distanceToStart + connection.cost;

          PathfindingNode? existingNeighborNode = nodeMap[neighbor];

          if (existingNeighborNode == null) {
            PathfindingNode newNeighborNode = PathfindingNode(
                neighbor,
                tentativeGScore,
                getEstimatedDistanceToEnd(neighbor.position, endNode.position),
                currentNode
            );
            openNodes.add(newNeighborNode);
            nodeMap[neighbor] = newNeighborNode;
          } else if (tentativeGScore < existingNeighborNode.distanceToStart) {
            existingNeighborNode.distanceToStart = tentativeGScore;
            existingNeighborNode.parent = currentNode;

            if (closedNodes.contains(existingNeighborNode)) {
              closedNodes.remove(existingNeighborNode);
              openNodes.add(existingNeighborNode);
            }
          }
        }
      }
    }

    print("no path found from $startPos to $endPos");
    return null;
  }

  double getEstimatedDistanceToEnd(Vector2 currentPos, Vector2 endPos) {
    return (currentPos.x - endPos.x).abs() + (currentPos.y - endPos.y).abs();
  }


  List<POINode> reconstructPath(PathfindingNode endNode) {
    List<POINode> path = [];
    PathfindingNode? current = endNode;

    while (current != null) {
      path.insert(0, current.poiNode);
      current = current.parent;
    }

    return path;
  }


  void debugDrawPath(Canvas canvas, List<POINode>? path) {
    if (path == null || path.isEmpty) return;

    Paint pathPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0;

    for (int i = 0; i < path.length - 1; i++) {
      Vector2 from = path[i].position * 32 + Vector2(16, 16);
      Vector2 to = path[i + 1].position * 32 + Vector2(16, 16);
      canvas.drawLine(from.toOffset(), to.toOffset(), pathPaint);
    }
  }


  @override
  FutureOr<void> onLoad() {
    priority = 1;
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    debugDrawPath(canvas, path);

    if(!level.player.debugMode) return;

    Vector2 selectedGridPos = (level.mouseCoords / 32)..floor();

    POINode? selectedNode = getNodeAt(selectedGridPos);


    if(selectedNode != null){


      List<POINodeConnection>? connections = selectedNode.connections;

      if(connections != null){



        Paint paint = Paint()..color = Colors.blue;
        paint.strokeWidth = 2.0;


        connections.forEach((element) {
          canvas.drawLine(selectedNode.position.toOffset() * 32 + Offset(16, 16), element.target.position.toOffset() * 32 + Offset(16, 16), paint);
        });

      }

    }

  }
}

class POINode {
  List<POINodeConnection>? connections = [];
  Vector2 position;

  POINode(this.position, [this.connections]) {
    connections ??= []; //if the connections are null, we create an empty list
  }

  void addConnection(POINodeConnection connection) =>
      connections!.add(connection);

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

class PathfindingNode {

  POINode poiNode;

  PathfindingNode? parent;

  double distanceToStart = 0;
  double estimatedDistanceToEnd = 0;

  double get totalCost => distanceToStart + estimatedDistanceToEnd;

  PathfindingNode(this.poiNode, this.distanceToStart, this.estimatedDistanceToEnd, [this.parent]);
}
