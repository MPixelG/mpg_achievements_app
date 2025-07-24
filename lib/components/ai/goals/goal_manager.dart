import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/ai/goals/goal.dart';

class GoalManager extends Component{

  void addGoal(Goal goal){
    parent!.add(goal);
  }

  double time = 0;
  @override
  void update(double dt) {
    super.update(dt);
    time += dt;

    Goal highestPriorityGoal = children.reduce((value, element) {
      if(value is Goal && value.prequisite(time)){
        if(element is Goal && element.prequisite(time)){

          if(value.goalPriority > element.goalPriority) {
            return value;
          } else {
            return element;
          }
        }
        return value;
      }
      return element;
    }) as Goal;


    highestPriorityGoal.updateGoal(dt);
  }


}