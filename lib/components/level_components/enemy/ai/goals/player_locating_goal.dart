import 'package:mpg_achievements_app/components/level_components/enemy/ai/goals/pathtracing_goal.dart';

class PlayerLocatingGoal extends PathtracingGoal {
  PlayerLocatingGoal(double goalPriority)
    : super((attributes) {
        if (attributes.time - (attributes.attributes["lastRaycast"] ?? 0) > 1) {
          attributes.attributes["lastRaycast"] = attributes.time;
          return true;
        }

        return false;

        /*      Vector2? nearestPlayerPos = attributes.attributes["nearestPlayerPosition"];
      Vector2? enemyPos = attributes.attributes["entityPos"];

      if(nearestPlayerPos == null || enemyPos == null) return true;


      bool trace = nearestPlayerPos.distanceTo(enemyPos) > 20;

      if(trace){
        attributes.attributes["lastRaycast"] = attributes.time;
        return true;
      }
      return false;*/
      }, goalPriority);
}
