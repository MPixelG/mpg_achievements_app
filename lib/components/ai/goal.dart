import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:mpg_achievements_app/components/ai/pathfinder.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';

import '../../mpg_pixel_adventure.dart';
import '../physics/collision_block.dart';

abstract class Goal extends Component { //a base goal class.
  bool done = false; //if the goal is done

  @override
  FutureOr<void> onLoad() {//init stuff
    done = false;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!done) { //as long as the goal isnt done, we perform a step.
      step();
    } else {
      removeFromParent(); //when the goal is done, we can detach it from the entity
    }
    super.update(dt);
  }

  void step() {} //a step function template

  bool isDone() => done; //returns if the goal is done
}

mixin GoalIncludesBasicMovement on PositionComponent, BasicMovement {
  late Vector2 endPos; //the end pos for the movement

  List<PathStep>? path = [];

  @override
  FutureOr<void> onLoad() {
    endPos = Vector2(16, 19);
    path = level.generator.getPathTo((position / 32), endPos);
    return super.onLoad();
  }

  void recalculatePath(Vector2 endPos){
    this.endPos = endPos;
    path = level.generator.getPathTo((position / 32)..floor(), endPos);
    if(path != null) currentStep = path![0];
    stepIndex = 0;
  }

  PathStep? currentStep;
  int stepIndex = 0;

  void updateGoal(double dt) {
    if (path == null || path!.isEmpty) {
      return;
    }

    currentStep = path![stepIndex];
    //print("nearest step at ${position.clone()..divide(Vector2(32, 32))..floor()} is $currentStep");


    Vector2 currentStepPosCenter = currentStep!.node.poiNode.position * 32 + Vector2.all(16);

    //print("current step: " + currentStep.toString());

    if(currentStepPosCenter.distanceTo(absoluteCenter) > 128) {
      currentStep = getNearestStep(absoluteCenter, path!);
      stepIndex = path!.indexOf(currentStep!);
    }

      //if the currently targeted node has been surpassed, we remove the element at the first position so that we automatically have the next target at first position
      if (absoluteCenter.distanceTo(currentStepPosCenter) < 15 && stepIndex < path!.length-1) {
        stepIndex++;
      } else if(stepIndex >= path!.length-1 && absoluteCenter.distanceTo(currentStepPosCenter) <= 10) {

      }

      if(stepIndex >= path!.length) {
        currentStep = null;
      }

      switch (currentStep?.action) {
        case PathfindingAction.walk:{
          adjustHorizontalMovementIfNeeded(currentStepPosCenter);
        }
        case PathfindingAction.jump:{
          if (isOnGround) jump();
          adjustHorizontalMovementIfNeeded(currentStepPosCenter);
        }
        case PathfindingAction.fall:{
          adjustHorizontalMovementIfNeeded(currentStepPosCenter);
        }
        case PathfindingAction.climbUp: {climb(currentStepPosCenter); adjustHorizontalMovementForClimbing(); break;}
        case PathfindingAction.climbDown: {climb(currentStepPosCenter); break;}
        default:{

          horizontalMovement = 0;

          if(path != null && path!.isNotEmpty) {
            currentStep = path![0];
          }

        }
      }
    }

  PathStep getNearestStep(Vector2 position, List<PathStep> path){
    return path.reduce((value, element) {

      //print("dist 1: (" + value.node.position.toString() + ")" + (value.node.position * 32).distanceTo(position).toString() + ", dist2: ("+ element.node.position.toString() + ")" + (element.node.position * 32).distanceTo(position).toString());

      PathStep nearestTarget = ((value.node.poiNode.position * 32).distanceTo(position) < (element.node.poiNode.position * 32).distanceTo(position)) ? value : element;

      if(hasClearPath(nearestTarget.node.poiNode.position  + Vector2.all(0.5), position / 32)) {
        return nearestTarget;
      } else{
        if(nearestTarget == value) {
          return element;
        } else {
          return value;
        }
      }
    });
  }

  bool hasClearPath(Vector2 firstPos, Vector2 otherPos) {
    if (firstPos.distanceTo(otherPos) < 0.01) { //if the 2 points are on the same spot, it has a clear path
      return true;
    }

    PixelAdventure game = (level.game as PixelAdventure); //get the game

    Vector2 direction = (otherPos - firstPos).normalized(); //calculate the direction of the 2 points

    Ray2 ray = Ray2(origin: firstPos * 32, direction: direction); //calculate the ray

    RaycastResult<ShapeHitbox>? result = game.collisionDetection.raycast( //and use it to raycast
      ray,
      maxDistance: firstPos.distanceTo(otherPos) * 32, //multiply by the tilesize because the current positions are grid positions
      hitboxFilter: (candidate) => candidate.parent is CollisionBlock && !(candidate.parent as CollisionBlock).isLadder
    );

    return result == null; //if the result is null, theres no collision
  }

  int accuracy = 20;

  void adjustHorizontalMovementIfNeeded(Vector2 goalPos) {
    double difference = (position - goalPos).x;


    double random = (accuracy - Random().nextInt(accuracy)).toDouble();

    bool move = random < difference.abs();

    if (move) {
      if (difference > 0) {
        horizontalMovement = -1;
      } else {
        horizontalMovement = 1;
      }
    } else {
      horizontalMovement = 0;
    }
  }

  void adjustHorizontalMovementForClimbing(){

    double difference = (position.x % 32);


    if(difference > 1) {
      if (difference > 0) {
        horizontalMovement = -1;
      } else {
        horizontalMovement = 1;
      }
    } else {
      horizontalMovement = 0;
    }


  }

  void climb(Vector2 goalPos) {
    double difference = (position - goalPos).y;


    double random = (accuracy - Random().nextInt(accuracy)).toDouble();

    bool move = random < difference.abs();

    if (move) {
      if (difference > 0) {
        verticalMovement = -0.03;
      } else {
        horizontalMovement = 0.03;
      }
    } else {
      horizontalMovement = 0;
    }
  }

  Vector2 get targetedPosition =>
      path?.elementAtOrNull(0)?.node.poiNode.position ??
      position; //returns the position of the currently targeted node. if the path is null, we return the current pos
  Level get level;
}

enum GoalType { idle, move, custom }
