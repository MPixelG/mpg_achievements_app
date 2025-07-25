import 'package:mpg_achievements_app/components/ai/goals/move_goal.dart';

class FollowPlayerGoal extends MoveGoal{
  FollowPlayerGoal(double goalPriority) : super((attributes) => true, goalPriority);
}