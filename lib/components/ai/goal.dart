import 'dart:async';

import 'package:flame/components.dart';

abstract class Goal extends Component{
  bool done = false;

  @override
  FutureOr<void> onLoad() {
    done = false;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if(!done){
      step();
    } else {
      removeFromParent();
    }
    super.update(dt);
  }

  void step(){}

  bool isDone() => done;
}

mixin GoalIncludesBasicMovement on Goal{
  late final Vector2 endPos;
  @override
  void step() {
    print("step");
    super.step();
  }
}

class MovementGoal extends Goal with GoalIncludesBasicMovement{
  MovementGoal(Vector2 goalPos) {
    endPos = goalPos;
  }
}



enum GoalType{
  idle, move, custom
}