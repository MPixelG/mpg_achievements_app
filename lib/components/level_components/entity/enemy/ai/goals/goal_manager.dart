import 'package:flame/components.dart';

import 'goal.dart';

class GoalManager extends Component {
  GoalAttributes attributes = GoalAttributes();

  void addGoal(Goal goal) {
    goal.attributes = attributes;
    add(goal);
  }

  @override
  void update(double dt) {
    super.update(dt);
    attributes.time += dt;

    final Iterable<Component> activeGoals = children.where((value) {
      if (value is Goal && value.prequisite(attributes)) {
        return true;
      }
      return false;
    });

    for (var element in activeGoals) {
      (element as Goal).updateGoal(dt);
    }
  }
}

class GoalAttributes {
  Map<String, dynamic> attributes = {};
  double time = 0;
}
