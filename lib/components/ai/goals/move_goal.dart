import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:mpg_achievements_app/components/ai/goals/goal.dart';
import 'package:mpg_achievements_app/components/ai/pathfinder.dart';
import 'package:mpg_achievements_app/components/level/game_world.dart';
import '../../../mpg_pixel_adventure.dart';
import '../../physics/collision_block.dart';
import '../../physics/movement.dart';

class MoveGoal extends Goal {


  late int goalKey;
  static int nextKeyIndex = 0;
  MoveGoal(super.prequisite, super.goalPriority){
    goalKey = nextKeyIndex++;
  }

  Vector2 get position => (parent!.parent! as PositionComponent).position;
  Vector2 get absoluteCenter => (parent!.parent! as PositionComponent).absoluteCenter;
  bool get isOnGround => (parent!.parent! as BasicMovement).isOnGround;
  bool get isShifting => (parent!.parent! as BasicMovement).isShifting;
  GameWorld get level => (parent!.parent! as HasGameReference<PixelAdventure>).game.gameWorld;


  set horizontalMovement(double pos) => (parent!.parent! as BasicMovement).horizontalMovement = pos;
  set verticalMovement(double pos) => (parent!.parent! as BasicMovement).verticalMovement = pos;
  set isShifting(bool val) => (parent!.parent! as BasicMovement).isShifting = val;




  late Vector2 endPos; //the end pos for the movement

  List<PathStep>? path = [];

  @override
  FutureOr<void> onLoad() {
    endPos = Vector2(-1, -1);
    path = level.generator.getPathTo(toGridPos(position), endPos);
    return super.onLoad();
  }

  void recalculatePath(Vector2 endPos) { //lets the entity walk to a given position
    this.endPos = endPos; //set the new end pos
    path = level.generator.getPathTo(toGridPos(position)..floor(), endPos); //generate the path
    stepIndex = 0; //reset the step index
    timeSinceLastPosChange = 0; //and the time since the position changed. this will be used for when the entity got off the path and is stuck now if it was stuck for over 3 secs, the path will be regenerated from that pos
  }

  PathStep? currentStep; //the current aimed pos
  int stepIndex = 0; //the index of that pos in the path

  double timeSinceLastPosChange = 0; //the time since the position changed. this will be used for when the entity got off the path and is stuck now if it was stuck for over 3 secs, the path will be regenerated from that pos
  Vector2 lastPosition = Vector2.zero(); //to check if the position changed

  @override
  void updateGoal(double dt) { //the update funktion


    attributes!.attributes["entityPos"] = position;

    if (path == null || path!.isEmpty) { //if theres no current path set or its empty, we have nothing left to do
      return;
    }


    currentStep = path![stepIndex]; //set the current step

    Vector2 currentStepPosCenter = toWorldPos(currentStep!.node.poiNode.position) + (tilesize.xy / 2); //the center of the currently aimed position.

    if (currentStepPosCenter.distanceTo(absoluteCenter) > 128) { //if we got off the path, we look at what the nearest node is. this way we automatically skip / get back to the right node.
      currentStep = getNearestStep(absoluteCenter, path!); //get the nearest node to that point. it also checks if theres line of sight between these points so that the entity doesnt target an impossible node.
      stepIndex = path!.indexOf(currentStep!); //get the index, so that it can increase from that node.
    }

    //if the currently targeted node has been surpassed, we move forward to the next one by increasing the step index.
    if (absoluteCenter.distanceTo(currentStepPosCenter) < 25 && // if were 15 px close to the node, we can already skip to the next one, to get a more fluid animation between the nodes.
        stepIndex < path!.length - 1) {
      stepIndex++; //increase the step index
    } else if (stepIndex >= path!.length - 1 &&
        absoluteCenter.distanceTo(currentStepPosCenter) <= 10) { //if its the last node of the path we have a smaller distance, so that the entity gets more centered at the end.
      currentStep = null; //set the current step to null, so that everything gets reset
    }

    switch (currentStep?.action) { //get the action of the step
      case PathfindingAction.walk:
        {
          adjustHorizontalMovementIfNeeded(currentStepPosCenter); // in case of walking, we just have to adjust the x coords in the direction of the given point.
        }
      case PathfindingAction.jump: //in case of jumping, we jump if we are on ground, because sometimes the jump is diagonal, we also adjust the x pos.
        {
          if (isOnGround) jump(); //jump if on ground
          adjustHorizontalMovementIfNeeded(currentStepPosCenter); //adjust x pos
        }
      case PathfindingAction.fall: //when falling we only have to adjust the x pos, because falling is handled for us by the BasicMovement gravity.
        {
          adjustHorizontalMovementIfNeeded(currentStepPosCenter); //adjust x pos
        }
      case PathfindingAction.climbUp: //when climbing up, we climb and also adjust the horizontal movement, so that we dont get stuck on a side.
        {
          climb(currentStepPosCenter); //climb
          adjustHorizontalMovementIfNeeded(currentStepPosCenter); //adjust the x pos so we dont get stuck
          break;
        }
      case PathfindingAction.climbDown: //when climbing down, we have to press shift, because otherwise we would just stand there on top of a ladder
        {
          isShifting = true; //shift so that if we stand on the top of the ladder we get down.
          climb(currentStepPosCenter);//climb
          adjustHorizontalMovementIfNeeded(currentStepPosCenter);//adjust the x pos so we dont get stuck
          break;
        }
      default:
        {
          horizontalMovement = 0; //if theres no current step, we just set all to movement to 0 so that we stay where we are.
          verticalMovement = 0;
        }
    }

    if ((toGridPos(lastPosition).clone()..floor()) == (toGridPos(position).clone()..floor())) //check if the current position and the last position are about the same.
      timeSinceLastPosChange += dt; //if they are, we increase the timer
    else {
      timeSinceLastPosChange = 0; //if the position changed, we reset the timer
    }

    if (timeSinceLastPosChange > 1.5 && currentStep != null) { //if we stayed at that pos and we have a current step, we are stuck.
      recalculatePath(endPos); //we recalculate the path to the endPos from the current pos.
      timeSinceLastPosChange = 0; //we reset the timer
      position.y -= 5; //and move a bit up, if we are glitched in the ground
    }

    lastPosition = position.clone(); //set the last position to the current position for the next update
  }

  ///returns the nearest step to the given position in the given path. it also checks if the 2 points have a clear path between them, so that you dont get a node that isn impossible to get to.
  PathStep getNearestStep(Vector2 position, List<PathStep> path) {
    return path.reduce((value, element) { //reduce means, that this will get executed until only one element is left. the element returned stays, the other one is removed.
      PathStep nearestTarget =
          (toWorldPos(value.node.poiNode.position).distanceTo(position) < //the distance from the current pos and the pos of the first val
              toWorldPos(element.node.poiNode.position).distanceTo(position)) //and the distance to the second val
          ? value : element; //the one with the shorter distance is the result.

      if (hasClearPath( //now we have to check if theres a clear path between the nearer point and the entity pos.
        nearestTarget.node.poiNode.position + Vector2.all(0.5), // +0.5 so that its centered
        toWorldPos(position))) { //convert the world pos to the grid pos
        return nearestTarget; //if it has a clear path we return the element with the shorter distance

      } else { //if theres no clear path between those, we return the other one.
        if (nearestTarget == value) { //we have to find out first, which of the elements was actually the one in the variable
          return element; //and then we return the other one
        } else {
          return value;
        }
      }
    });
  }

  ///uses raycasting to check if theres an intersection between the 2 given points
  bool hasClearPath(Vector2 firstPos, Vector2 otherPos) {
    if (firstPos.distanceTo(otherPos) < 0.01) {
      //if the 2 points are on the same spot, it has a clear path
      return true;
    }

    PixelAdventure game = level.game; //get the game

    Vector2 direction = (otherPos - firstPos)
        .normalized(); //calculate the direction of the 2 points

    Ray2 ray = Ray2(
      origin: toWorldPos(firstPos), //convert the grid pos to the world pos
      direction: direction,
    ); //calculate the ray

    RaycastResult<ShapeHitbox>? result = game.collisionDetection.raycast(
      //and use it to raycast
      ray,
      maxDistance: firstPos.distanceTo(toWorldPos(otherPos)),
      //multiply by the tilesize because the current positions are grid positions
      hitboxFilter: (candidate) =>
          candidate.parent is CollisionBlock && //we only want to check for collision blocks
          !(candidate.parent as CollisionBlock).isLadder, //and ignore ladders, because these are walkthrough
    );

    return result == null; //if the result is null, theres no collision
  }

  int accuracy = 1;//the accuracy brings a bit of randomness in the movement. increase the value to get more random movement. it gets stronger the nearer you are to your destination.


  void adjustHorizontalMovementIfNeeded(Vector2 goalPos) {
    double difference = (position - goalPos).x; // the difference between the current pos and the given one.

    double random = (Random(goalKey).nextInt(accuracy)).toDouble(); //get a random val from 0 to accuracy.

    bool move = random + 5 < difference.abs(); //if the difference is smaller than a random val between 0 and accuracy, we dont move.
    // this simulates a bit of randomness and makes you walk not exactly at the destination but only at the area.

    if (move) { //if we move
      if (difference > 0) { //we check in which direction we have to go
        horizontalMovement = -1; //and then set the horizontal movement.

      } else {
        horizontalMovement = 1;
      }
    } else {
      horizontalMovement = 0; //if we dont move, we reset the horizontal movement to 0 so that we stop. we will still glide a bit though because of the x velocity.
    }
  }

  ///makes you climb on a ladder to the given point.
  void climb(Vector2 goalPos) {
    double difference = (position - goalPos).y; //the height to climb. can also be negative to climb down.

    double random = (accuracy - Random().nextInt(accuracy)).toDouble(); //get a random val from 0 to accuracy.

    bool move = random < difference.abs(); //if the difference is smaller than a random val between 0 and accuracy, we dont move.
    // this simulates a bit of randomness and makes you walk not exactly at the destination but only at the area.

    if (move) {//if we move
      if (difference > 0) { //we check in which direction we have to go
        verticalMovement = -0.06; //climb up
      } else {
        verticalMovement = 0.06; //climb down
      }
    } else {
      verticalMovement = 0; //if we dont move, we reset the horizontal movement to 0 so that we stop. we will still glide a bit though because of the y velocity.
    }
  }

  Vector2 get targetedPosition => //returns the position of the currently targeted node. if the path is null, we return the current pos
      path?.elementAtOrNull(0)?.node.poiNode.position ??
      position;

  void jump() {(parent!.parent! as BasicMovement).jump();}


  Vector2 toWorldPos(Vector2 val){
    return Vector2(val.x * tilesize.x, val.y * tilesize.y);
  }
  Vector2 toGridPos(Vector2 val){
    return Vector2(val.x / tilesize.x, val.y / tilesize.y);
  }

}

enum GoalType { idle, move, custom }
