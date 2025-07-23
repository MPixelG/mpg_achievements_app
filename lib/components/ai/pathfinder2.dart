import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/geometry.dart';
import 'package:flame_tiled/flame_tiled.dart';
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

class POIGenerator {
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

  void onClick(TapDownEvent event) {
    Vector2 gridPos = (level.mousePos / 32)
      ..floor()
      ..round();

    POINode? node = getNodeAt(gridPos);

    if (node != null) {
      print(node);
    }

    print("clicked at " + gridPos.toString());
    print(
      "height to next ceiling: " +
          getHeightToNextCeiling(gridPos, maxHeightToCheck: 100).toString(),
    );
    print("node: " + getNodeAt(gridPos).toString());
    print("clearPath? " + hasClearPath(lastClickPoint, gridPos).toString());

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
      print(
        "destination at " +
            node.position.toString() +
            ": " +
            jumpDestination.toString(),
      );

      if (!hasClearPath(node.position, jumpDestination)) {
        print("didnt add bc theres no clear path");

        return;
      }

      POINode? nodeAtDestination = getNodeAt(jumpDestination);

      if (nodeAtDestination != null) {
        POINodeConnection connection = POINodeConnection(
          nodeAtDestination,
          PathfindingAction.jump,
          differenceX.abs() / 2,
        );
        node.addConnection(connection);
        print(
          "added connection at ${node.position.toString()} to ${jumpDestination.toString()}",
        );
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
