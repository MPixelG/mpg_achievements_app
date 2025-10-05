import 'package:flame/components.dart';

import '../../../../../../mpg_pixel_adventure.dart';
import '../../../player.dart';
import 'move_goal.dart';

class FollowPlayerGoal extends MoveGoal {
  Player playerToFollow;
  FollowPlayerGoal(double goalPriority, this.playerToFollow)
    : super((attributes) => true, goalPriority);

  double lastPlayerSighting = double.infinity;

  @override
  void updateGoal(double dt) {
    Vector2? lastPlayerPos = attributes!.attributes["nearestPlayerPosition"];
    lastPlayerSighting += dt;
    if (lastPlayerPos != null) {
      if ((lastPlayerPos..divide(tilesize.xy)).distanceTo(endPos) > 2) {
        recalculatePath((lastPlayerPos..divide(tilesize.xy))..floor());
      }
      lastPlayerSighting = 0;
      attributes!.attributes["nearestPlayerPosition"] = null;
    } else if (lastPlayerSighting > 0.5 && lastPlayerSighting < 2) {
      recalculatePath(
        (playerToFollow.absoluteCenter..divide(tilesize.xy))..floor(),
      );
      lastPlayerSighting = double.infinity;
    }

    super.updateGoal(dt);
  }
}
