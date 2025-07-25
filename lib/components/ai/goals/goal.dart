import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/goals/goal_manager.dart';

abstract class Goal extends Component{


  double goalPriority;
  bool Function(GoalAttributes attributes) prequisite;
  bool repeat;

  GoalAttributes? attributes;

  bool _done = false;


  Goal(this.prequisite, this.goalPriority, [this.repeat = true]);

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) {
      removeFromParent();
    }
  }

  void updateGoal(double dt);
}