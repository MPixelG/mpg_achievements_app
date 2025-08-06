import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:flame/events.dart';
import 'package:flame/geometry.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/ai/tile_grid.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/physics/collision_block.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

enum PathfindingAction { walk, jump, fall, climbUp, climbDown }

class POIGenerator extends Component with HasGameReference<PixelAdventure>{
  Level level; //the level where the pathfinding happens

  late TileGrid grid; // a grid that contains a state for every tile. for example solid, platform, ladder, air, etc.

  late List<POINode> nodes; //all of the POI nodes. a POI (Point of Interest) is a point in the world, that can be used to get from one point to another by chaining those together.

  Vector2 get tilesize => level.tilesize;

  POIGenerator(this.level) { //the constructor
    grid = TileGrid( //initialize the grid.
      (level.level.width / tilesize.x).toInt(),
      (level.level.height / tilesize.y).toInt(),
      tilesize,
      level.level.tileMap.getLayer("Collisions") as ObjectGroup,
    );
    level.add(grid); //add the grid to the level to show some debug render stuff.

    nodes = []; //initialize the nodes with an empty list.
    addAllNodes(); //adds all of the different nodes and their connections.
  }

  Vector2 lastClickPoint = Vector2(0, 0);

  List<PathStep>? path;

  void onClick(TapDownEvent event) {
    Vector2 gridPos = (toGridPos(level.mousePos))
      ..floor(); //converts the mouse position on the screen to a grid position

    POINode? node = getNodeAt(gridPos); //the node at the clicked field

    if (node != null) { //the node is null if theres no node at the given position
      print(node.toString());
    } else print("node is null!");



    print("clear path? " + hasClearPath(lastClickPoint, gridPos).toString());

    path = getPathTo(lastClickPoint, gridPos); // calculates the shortest path between the clicked mouse position and the last clicked mouse position
    lastClickPoint = gridPos.clone();

  }


  ///gives all of the empty nodes connections to other nodes
  void addAllNodes() {
    int x = 0;
    grid.grid.forEach((element) { //every row
      int y = 0;
      element.forEach((element) { //every commumn in that row -> every field
        if (element != TileType.solid) { //if its not solid, we add a node, because the entity is able to get there.
          nodes.add(POINode(Vector2(x.toDouble(), y.toDouble())));
        }
        y++;
      });

      x++;
    });

    addWalkableNodeConnections(); //adds all the connections for walking
    addFallNodeConnections(); //adds all the connections for falling
    addJumpNodeConnections(); //adds all the connections for jumping. also includes diagonal jumps.
    addClimbingNodeConnections();
  }

  void addWalkableNodeConnections() {
    nodes.forEach((node) { //for every generated node
      if (isOnGround(node.position)) { //if its on the ground you can walk on it
        if (grid.isFree(node.position + Vector2(1, 0))) { //if the other position is not solid, we can walk there.
          POINode? other = getNodeAt(node.position + Vector2(1, 0));
          if (other != null) { //its null if it doesnt exist.
            node.addConnection(
              POINodeConnection(other, PathfindingAction.walk, 0.5), //adds the connection with a cost of 0.5.
            );
          }
        }

        if (grid.isFree(node.position + Vector2(-1, 0))) { //the same for walking left.
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
    nodes.forEach((node) { //for every generated node
      if (!isOnGround(node.position)) { //if its in the air, we can fall
        Vector2 posDownLeft = node.position + Vector2(-1, 1); //all the positions we can fall to. this also includes moving while falling.
        Vector2 posDown = node.position + Vector2(0, 1);
        Vector2 posDownRight = node.position + Vector2(1, 1);

        POINode? otherLeft;
        if (grid.isFree(posDownLeft) && grid.valAt(posDownLeft) != TileType.platform) otherLeft = getNodeAt(posDownLeft); //if theres an empty space there, we try to get the node.

        POINode? otherDown;
        if (grid.isFree(posDown)) otherDown = getNodeAt(posDown); //same for down

        POINode? otherRight;
        if (grid.isFree(posDownRight) && grid.valAt(posDownRight) != TileType.platform) otherRight = getNodeAt(posDownRight); //and right.

        if (otherDown != null) { //if the node doesnt exist, we dont add it.
          node.addConnection(
            POINodeConnection(otherDown, PathfindingAction.fall, 0.3),
          );
        }


        if (otherLeft != null) { //same for down left
          node.addConnection(
            POINodeConnection( //we add the connection
              otherLeft,
              PathfindingAction.fall,
              0.3, //with a cost of 0.3 (lower than walking)
            ),
          );
        }

        if (otherRight != null) { //and right.
          node.addConnection(
            POINodeConnection(
              otherRight,
              PathfindingAction.fall,
              0.3,
            ),
          );
        }
      }
    });
  }
  void addJumpNodeConnections() {
    nodes.forEach((node) { //for every generated node
      if (isOnGround(node.position) && grid.valAt(node.position) != TileType.ladder) { //if the entity is on the ground, it can jump. you cant jump inside a ladder.
        addJumpNodeInDirection(node, 0); //jump op
        addJumpNodeInDirection(node, 1); //jump right
        addJumpNodeInDirection(node, 2); //jump right far
        addJumpNodeInDirection(node, -1); //jump left
        addJumpNodeInDirection(node, -2); //jump left far
      }
    });
  }
  void addJumpNodeInDirection(POINode node, double differenceX) {
    int heightToCeiling = getHeightToNextCeiling( //get the height to the ceiling. used to find out if the jump is even possible if theres a ceiling over your head.
      node.position,
      maxHeightToCheck: 2, //check 2 blocks max, because you can only jump 2 blocks high
    );

    if (heightToCeiling > differenceX.abs()) { // more diagonal jumps take higher ceilings
      Vector2 jumpDestination = //calculate the destination
      node.position + Vector2(differenceX, -heightToCeiling.toDouble());

      if (!hasClearPath(node.position,
          jumpDestination)) { //calculate if theres a clear path between the jump point and the destination
        return; //if not, you cant jump and there is no connection.
      }

      POINode? nodeAtDestination = getNodeAt(
          jumpDestination); //get the node to connect them

      if (nodeAtDestination != null) { //check if its null
        POINodeConnection connection = POINodeConnection(
          nodeAtDestination,
          PathfindingAction.jump,
              2, //it has a base cost of 2 and increases if you jump diagonally. this prevents the entity from jumping all the time
        );
        node.addConnection(connection); //add the connection
      }
    }
  }


  void addClimbingNodeConnections(){
    nodes.forEach((node) { //for every generated node
      if(grid.valAt(node.position) == TileType.ladder) {
        Vector2 posUp = node.position + Vector2(0, -1);
        Vector2 posDown = node.position + Vector2(0, 1);

        bool isLadderOrAirUp = grid.isFree(posUp);
        bool isLadderOrAitDown = grid.isFree(posDown);

        POINode? nodeUp = getNodeAt(posUp);
        POINode? nodeDown = getNodeAt(posDown);

        if (nodeUp != null && isLadderOrAirUp) {
          POINodeConnection connection = POINodeConnection(
            nodeUp,
            PathfindingAction.climbUp,
            0.7, //it has a base cost of 2 and increases if you jump diagonally. this prevents the entity from jumping all the time
          );
          node.addConnection(connection);
        }
        if (nodeDown != null && isLadderOrAitDown) {
          POINodeConnection connection = POINodeConnection(
            nodeDown,
            PathfindingAction.climbDown,
            0.7, //it has a base cost of 2 and increases if you jump diagonally. this prevents the entity from jumping all the time
          );
          node.addConnection(connection);
        }
      } else if(grid.valAt(node.position) == TileType.air){

        Vector2 posDown = node.position + Vector2(0, 1);
        if(grid.valAt(posDown) == TileType.ladder){
          POINode? nodeDown = getNodeAt(posDown);
          if (nodeDown != null) {
            POINodeConnection connection = POINodeConnection(
              nodeDown,
              PathfindingAction.climbDown,
              0.7, //it has a base cost of 2 and increases if you jump diagonally. this prevents the entity from jumping all the time
            );
            node.addConnection(connection);
          }


        }

      }
    });

  }

  ///ray traces if theres a clear path between the 2 given points.
  bool hasClearPath(Vector2 firstPos, Vector2 otherPos) {
    if (firstPos.distanceTo(otherPos) < 0.01) { //if the 2 points are on the same spot, it has a clear path
      return true;
    }

    PixelAdventure game = level.game; //get the game

    Vector2 direction = (otherPos - firstPos).normalized(); //calculate the direction of the 2 points

    Ray2 ray = Ray2(origin: toWorldPos(firstPos), direction: direction); //calculate the ray

    RaycastResult<ShapeHitbox>? result = game.collisionDetection.raycast( //and use it to raycast
      ray,
      maxDistance: firstPos.distanceTo(toWorldPos(otherPos)), //multiply by the tilesize because the current positions are grid positions
      hitboxFilter: (candidate) => candidate.parent is CollisionBlock && !(candidate.parent as CollisionBlock).isLadder,
    );

    return result == null; //if the result is null, theres no collision
  }

  //returns the height of the nearest ceiling at a given point.
  int getHeightToNextCeiling(Vector2 pos, {int maxHeightToCheck = 3}) {
    for (int currentHeightDifference = 0; currentHeightDifference <= maxHeightToCheck; currentHeightDifference++) { //for all of he different possible heights
      if (grid.isBlocked(pos + Vector2(0, -currentHeightDifference.toDouble()),)) { //if the position is blocked, theres a ceiling.
        return currentHeightDifference;
      }
    }
    return maxHeightToCheck; // there was no collision, so we give back the max height.
  }

  //returns if the given position is solid.
  bool isOnGround(Vector2 pos) {
    TileType tileBelow = grid.valAt(pos + Vector2(0, 1)); //get the tile below the given pos
    bool isFieldFree = grid.isFree(pos);

    return (tileBelow == TileType.solid || //if the field below is solid, a ladder or a platform, your standing on sth solid.
            tileBelow == TileType.ladder ||
            tileBelow == TileType.platform) &&
        isFieldFree; //if your currently inside of sth, your not on the ground.
  }

  POINode? getNodeAt(Vector2 pos) {
    Vector2 goalPos = pos.clone()..floor();
    try {
      return nodes.firstWhere((element) => element.position == goalPos); //get the first node where the position fits the given one
    } on StateError { //a state error is thrown if theres no element with the given filter
      return null; //then we return null
    }
  }



  List<PathStep>? getPathTo(Vector2 startPos, Vector2 endPos) {
    POINode? startNode = getNodeAt(startPos); //the node at the start of the path
    POINode? endNode = getNodeAt(endPos); //the node at the end of the path. we want to connect those two

    if (startNode == null || endNode == null) { //if one of those is null, they are inside of a wall or sth.
      return null; //we return bc its not possible to generate the path.
    }

    if (startNode == endNode) { // if the start is the end, the path is empty, because were already there.
      return [PathStep(PathfindingNode(startNode, 0, getEstimatedDistanceToEnd(startNode.position, endNode.position)), PathfindingAction.walk)]; //we return one empty step.
    }


    // this is a collection of Nodes that still have to be looked at. all the discovered nodes will be added to this. These will always get sorted by probability of being the best fitting one.
    Set<PathfindingNode> openNodes = {};

    //this is a list of nodes that are already done and wont be changed. over time openNodes nodes will be moved here to create the perfect path.
    Set<PathfindingNode> closedNodes = {};
    Map<POINode, PathfindingNode> nodeMap = {}; //to look up if the POINode is already linked up with a Pathfinding node, so that it doesnt need to be calculated every step.

    PathfindingNode startPathNode = PathfindingNode( //the very first Pathfinding node! The pathfinding nodes are upgraded versions of POINodes, that contain some extra infos, like the distance to the end or the used connection of the given node.
        startNode,
        0, // it has a distance of 0 to the start.
        getEstimatedDistanceToEnd(startNode.position, endNode.position)
    );
    openNodes.add(startPathNode); //add it to the open nodes
    nodeMap[startNode] = startPathNode; //link the start node to the Pathfinding node variant

    while (openNodes.isNotEmpty) { // break when the best path has been found (return statement) or if all discovered nodes have been looked at and didnt give a good result. this means the path is not possible and null will be returned.
      PathfindingNode currentNode = openNodes.reduce( //get the one with the lowest total cost. the total cost is the sum of the distance to the start and the calculated distance to the end.
              (a, b) => a.totalCost < b.totalCost ? a : b
      );

      if (currentNode.poiNode == endNode) { //if we arrived at the end were done!
        return reconstructPath(currentNode); //now we have to convert the singular node to the path. we do this by looking at the parent of the node. that gives us the next node and we can get that parent again.
      }

      openNodes.remove(currentNode); //we move it from the open nodes to the closed ones.
      closedNodes.add(currentNode);

      if (currentNode.poiNode.connections != null) { //if it has connections
        for (POINodeConnection connection in currentNode.poiNode.connections!) { //we iterate over every one of them
          POINode neighbor = connection.target;

          if (closedNodes.any((node) => node.poiNode == neighbor)) { //if we already have this node in our path, we wont add it, because otherwise it will create a loop.
            continue;
          }

          double score = currentNode.distanceToStart + connection.cost; //we calculate the score by getting the distance to the start and adding the cost of the movement type to it. this makes the entity more probable of walking than jumping all the time for example.

          PathfindingNode? existingNeighborNode = nodeMap[neighbor]; // we look if we already have a Pathfinding node for this POI Node

          if (existingNeighborNode == null) { //if we dont have one we have to create it.
            PathfindingNode newNeighborNode = PathfindingNode(
                neighbor, // the POI Node
                score, //the score
                getEstimatedDistanceToEnd(neighbor.position, endNode.position), //we calculate the distance to the end
                currentNode, // set this node as a parent
                connection // and set the used connection to the current one.
            );
            openNodes.add(newNeighborNode); //we add it to the discovered nodes.
            nodeMap[neighbor] = newNeighborNode; //and add it to the map.
          } else if (score < existingNeighborNode.distanceToStart) { //if doesnt bring us nearer to the end, we need to remove it from the closed nodes again
            existingNeighborNode.distanceToStart = score; //we set the score to the calculated one
            existingNeighborNode.parent = currentNode; //set this node as a parent
            existingNeighborNode.usedConnection = connection; //and set the current connection as the used connection.

            if (closedNodes.contains(existingNeighborNode)) {
              closedNodes.remove(existingNeighborNode); //we remove it from the closed nodes
              openNodes.add(existingNeighborNode); //and re-add it to the open ones, because it could turn out to be actually good at the end.
            }
          }
        }
      }
    }

    //there was no path found, because its not possible
    return null;
  }

  double getEstimatedDistanceToEnd(Vector2 currentPos, Vector2 endPos) {
    return (currentPos.x - endPos.x).abs() + (currentPos.y - endPos.y).abs(); //we calculate an estimated distance to the end.
  }

  //we reconstruct the given end node by adding the parent of the node to a list and repeat that with the parent of that node.
  List<PathStep> reconstructPath(PathfindingNode endNode) {
    List<PathStep> path = []; //an empty path initialization
    PathfindingNode? current = endNode; //set the current node to the end node.

    while (current != null) { //when the node is null, it has to be the start one, because its the only one that doesnt hava a parent.
      if (current.usedConnection != null) { //if no connection was used to get to the parent sth didnt work as expected.
        path.insert(0, PathStep(
            current, // set the node,
            current.usedConnection!.action, //the action used
            current.usedConnection!.cost  //and the cost.
        ));
      } else {
        path.insert(0, PathStep(current, PathfindingAction.walk)); //if no connection was used, we add a step with no action used to get there.
      }
      current = current.parent; //set the current one to the parent and repeat.
    }
    return path; //return the path
  }


  void debugDrawPathWithActions(Canvas canvas, List<PathStep> path) { //visualizes the given path. marks all of the nodes used as circles and the connections with lines and colors them depending on the action used.
    if (path.length < 2) return; //if the path is shorter than 2 points, it cant have any movements in it, because one of them is the start and the other one is the end point.

    for (int i = 0; i < path.length - 1; i++) { //for every point in the path
      Vector2 from = toWorldPos(path[i].node.poiNode.position) + (tilesize / 2); //calculate the position to use. add another 16 to center the point in the field
      Vector2 to = toWorldPos(path[i + 1].node.poiNode.position) + (tilesize / 2); //same for the destination point.

      Paint pathPaint = Paint()..strokeWidth = 3.0; //set the stroke width to 3

      PathfindingAction? nextAction = path[i + 1].action; //get the next action to color
      switch (nextAction) {
        case PathfindingAction.walk: //green for walking
          pathPaint.color = Colors.green;
          break;
        case PathfindingAction.jump: //blue for jumping
          pathPaint.color = Colors.blue;
          break;
        case PathfindingAction.fall: //red for falling
          pathPaint.color = Colors.red;
          break;
        case PathfindingAction.climbUp: //orange for climbing up
          pathPaint.color = Colors.orange;
          break;
        case PathfindingAction.climbDown: //purple for climbing down
          pathPaint.color = Colors.purple;
          break;
        default:
          pathPaint.color = Colors.grey; //and grey for idk what
      }

      canvas.drawLine(from.toOffset(), to.toOffset(), pathPaint); //draw the line

      Paint dotPaint = Paint() //also create a paint for the dots that mark the different nodes.
        ..color = pathPaint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(from.toOffset(), 4, dotPaint); //draw a circle to mark the node
    }

    if (path.isNotEmpty) { //also draw a yellow dot at the end of the path
      Vector2 endPos = (toWorldPos(path.last.node.poiNode.position)) + (tilesize / 2); //calculate the end pos with a little offset to center it
      Paint endPaint = Paint() // a custom paint
        ..color = Colors.yellow //in yellow
        ..style = PaintingStyle.fill; //and mark it as fill so that not only the outline of the circle will get drawn
      canvas.drawCircle(endPos.toOffset(), 6, endPaint); //draw the end point
    }
  }


  @override
  FutureOr<void> onLoad() {
    priority = 1; //set the priority to one so that the debug stuff gets drawn above everything else
    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if(path != null) { //if the path is null, it hasnt been created yet, because the user didnt click yet.
      debugDrawPathWithActions(canvas, path!); //if its not null we can draw it
    }

    if(!level.player.debugMode) return; // everything else only gets drawn in debug mode. so we return if thats not the case

    Vector2 selectedGridPos = (toGridPos(level.mousePos))..floor(); //convert the mouse pos to a grid pos

    POINode? selectedNode = getNodeAt(selectedGridPos); //and get the node at that position


    if(selectedNode != null){ //if the node is null, we dont draw


      List<POINodeConnection>? connections = selectedNode.connections; //get all of the connections

      if(connections != null){ // if it has connections we can draw those

        Paint paint = Paint()..color = Colors.blue; //we will draw all of the connections with blue paint
        paint.strokeWidth = 2.0; //and a stroke width of 2


        connections.forEach((element) { //now draw a line for every connection from the node position to the target of the connection. also add a bit of offset for centering again.
          canvas.drawLine((toWorldPos(selectedNode.position) + (tilesize / 2)).toOffset(), (toWorldPos(element.target.position) + (tilesize / 2)).toOffset(), paint);
        });
      }
    }
  }

  Vector2 toGridPos(Vector2 pos){
    return Vector2(pos.x / tilesize.x, pos.y / tilesize.y);
  }
  Vector2 toWorldPos(Vector2 pos){
    return Vector2(pos.x * tilesize.x, pos.y * tilesize.y);
  }

}

class POINode { //this node is used for directiong an entity around. A POI (Point of Interest) is a point in the world, that can be used to get from one point to another by chaining those together.
  List<POINodeConnection>? connections = []; //it can have multiple connections to chain together multiple nodes in a big network.
  Vector2 position;

  POINode(this.position, [this.connections]) { //basic constructor with the position
    connections ??= []; //if the connections are null, we create an empty list
  }

  void addConnection(POINodeConnection connection) =>
      connections!.add(connection); //adds a given connection to the connection list.

  @override
  String toString() {
    return "node at ${position.toString()}";
  }

  @override
  bool operator ==(Object other) {
    if(other is! POINode) return false;
    if(other.connections != connections) return false;
    if(other.position != position) return false;

    return true;
  }

}

class POINodeConnection { //a connection that connects 2 POI Nodes. it contains
  POINode target; //the node it connects to
  PathfindingAction action; //the action used to get from one node to the chained one. This could be walking, jumping, climbing, falling etc.
  double cost; //the cost it takes to perform the action. this prevents the entity from jumping all the time for example.

  POINodeConnection(this.target, this.action, this.cost);

  @override
  bool operator ==(Object other) {
    if(other is! POINodeConnection) return false;
    if(other.target != target) return false;
    if(other.action != action) return false;
    if(other.cost != cost) return false;


    return true;
  }

}

///an upgraded version of the [POINode]. it contains a POI Node and also some extra info like the connection used to get to the node, the parent of this node and distance to start and end.
class PathfindingNode {
  POINode poiNode; //the contained node
  POINodeConnection? usedConnection; //the connection used to get to this node.

  PathfindingNode? parent; //the parent of this node. this lets you chain multiple Pathfinding Nodes together and create a Path to use.

  double distanceToStart = 0; // the distance to the start. this also includes all of the costs of the actions used.
  double estimatedDistanceToEnd = 0; // a calculated distance to the end.

  double get totalCost => distanceToStart + estimatedDistanceToEnd; // this is and indicator of how good this node is from getting frome one point to another, because it contains the total length from the start to the end and this gets lower if less actions with heigh costs have been used.

  PathfindingNode(this.poiNode, this.distanceToStart, this.estimatedDistanceToEnd, [this.parent, this.usedConnection]); //just a basic constructor
}

//this is used for the end result of the pathtracing. it contains the node, the action and the cost, so that any entity can navigate around with this info.
class PathStep {
  PathfindingNode node; //the node used
  PathfindingAction? action; //the action used
  double cost; //the cost it took to perform this action

  PathStep(this.node, [this.action, this.cost = 0]); //basic constructor


  @override
  String toString() {
    return "${node.toString()} : ${action.toString()}";
  }

  @override
  bool operator ==(Object other) {
    if(other is! PathStep) return false;

    if(other.node != node) return false;

    if(other.action != action) return false;

    return  true;
  }
}