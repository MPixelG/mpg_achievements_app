import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/pathfinder.dart';
import 'package:mpg_achievements_app/components/level.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';

abstract class Goal extends Component {
  bool done = false;

  @override
  FutureOr<void> onLoad() {
    done = false;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!done) {
      step();
    } else {
      removeFromParent();
    }
    super.update(dt);
  }

  void step() {}

  bool isDone() => done;
}

mixin GoalIncludesBasicMovement on PositionComponent, BasicMovement {
  late Vector2 endPos;

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
  }

  PathStep? currentStep;

  void updateGoal(double dt) {
    if (path == null || path!.isEmpty) {
      return;
    }

    if (position.distanceTo(path![0].node.position * 32) <= 32) {
      path!.removeAt(0);
    } //if the currently targeted node has been surpassed, we remove the element at the first position so that we automatically have the next target at first position
    if(path!.isNotEmpty) {
      currentStep = path![0];
    } else {
      currentStep = null;
    }


    switch (currentStep?.action) {
      case PathfindingAction.walk:{
          adjustHorizontalMovementIfNeeded(currentStep!.node.position * 32);
        }
      case PathfindingAction.jump:{
          if (isOnGround) jump();
          adjustHorizontalMovementIfNeeded(currentStep!.node.position * 32);
        }
      case PathfindingAction.fall:{
          adjustHorizontalMovementIfNeeded(currentStep!.node.position * 32);
        }
      case PathfindingAction.climbUp:
      case PathfindingAction.climbDown:
      default:{

        horizontalMovement = 0;

        if(path != null && path!.isNotEmpty) {
          currentStep = path![0];
        }

    }
    }
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

  Vector2 get targetedPosition =>
      path?.elementAtOrNull(0)?.node.position ??
      position; //returns the position of the currently targeted node. if the path is null, we return the current pos
  Level get level;
}

enum GoalType { idle, move, custom }
