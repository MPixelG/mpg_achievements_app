import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/player.dart';

enum PlayerHitboxVariant {
  head, body, rightFoot, leftFoot
}

class PlayerHitbox extends Component with HasCollisionDetection { //OUTDATED
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
      position: Vector2(5, player.height - 5),
      size: Vector2(player.width / 3, 5),
    )..allowSiblingCollision = true;

    rightFoot = RectangleHitbox(
        position: Vector2((player.width / 3) * 2, player.height - 5),
        size: Vector2(player.width / 3 - 5, 5)
    )..allowSiblingCollision = true;

    head = RectangleHitbox(
        position: Vector2((player.width - headWidth) / 2, 6),
        size: Vector2(headWidth * 2, headHeight)
    )..allowSiblingCollision = true;

    body = RectangleHitbox(
        position: Vector2((player.width - bodyWidth) / 2, headHeight + 6),
        size: Vector2(bodyWidth * 2, bodyHeight - headHeight - 7)
    );

    add(leftFoot);
    add(rightFoot);
    add(head);
    add(body);
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
    Player parent = this.parent as Player;
    updatePositions(parent);
    return leftFoot.isColliding || rightFoot.isColliding || body.isColliding || head.isColliding; //refractoring
  }

  void updatePositions(Player player) {
    leftFoot.position = Vector2(5, player.height - 5);
    rightFoot.position = Vector2((player.width / 3) * 2, player.height - 5);
    head.position = Vector2((player.width - headWidth) / 2, 6);
    body.position = Vector2((player.width - bodyWidth) / 2, headHeight + 6);
  }

  void updateAbsolutePositions(Vector2 playerPos, double playerWidth, double playerHeight) {
    leftFoot.position = Vector2(playerPos.x + 5, playerPos.y + playerHeight - 5);
    rightFoot.position = Vector2(playerPos.x + (playerWidth / 3) * 2, playerPos.y + playerHeight - 5);
    head.position = Vector2(playerPos.x + (playerWidth - headWidth) / 2, playerPos.y + 6);
    body.position = Vector2(playerPos.x + (playerWidth - bodyWidth) / 2, playerPos.y + headHeight + 6);
  }


}