import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:mpg_achievements_app/components/player.dart';

enum PlayerHitboxVariant {
  head, body, rightFoot, leftFoot
}

//a special hitbox for players that differenciates between collisions of feet, head and body. this can be useful to check if the player is for example standing on an edge, hits his head or gets hit by an enemy.
class PlayerHitbox extends Component with HasCollisionDetection{
  final double headWidth = 6;
  final double headHeight = 6;

  final double bodyWidth = 7;
  final double bodyHeight = 28;

  late RectangleHitbox leftFoot;
  late RectangleHitbox rightFoot;
  late RectangleHitbox head;
  late RectangleHitbox body;

  PlayerHitbox(Player player) {
    leftFoot = RectangleHitbox(
        position: Vector2(5, player.height - 5), //in the bottom left corner
        size: Vector2(player.width / 3, 5), // 5 px height and a third of the player width wide

    );

    rightFoot = RectangleHitbox( //same for the right foot but mirrored
        position: Vector2((player.width / 3) * 2, player.height - 5),
        size: Vector2(player.width / 3 - 5, 5)
    );

    head = RectangleHitbox(
        position: Vector2((player.width - headWidth) / 2, 6), //in the top middle
        size: Vector2(headWidth * 2, headHeight)
    );

    body = RectangleHitbox(
        position: Vector2((player.width - bodyWidth) / 2, headHeight + 6), //from the end of the head to the beginning of the feet
        size: Vector2(bodyWidth * 2, bodyHeight - headHeight - 7)
    );

  }

  Set<ShapeHitbox> getAllActiveCollisions() {
    Set<ShapeHitbox> all = {};
    all.addAll(leftFoot.activeCollisions);
    all.addAll(rightFoot.activeCollisions);
    all.addAll(body.activeCollisions);
    all.addAll(head.activeCollisions);

    return all;
  }

  bool isColliding() {
    bool leftFootColliding = !leftFoot.activeCollisions.isEmpty;
    if (leftFootColliding)
        print('left foot collided');
    return leftFoot.isColliding || rightFoot.isColliding || body.isColliding || head.isColliding;
  }


}