// lib/components/utils.dart

import 'package:mpg_achievements_app/components/collision_block.dart';
import 'package:mpg_achievements_app/components/player.dart';

bool checkCollision(Player player, CollisionBlock block) {
  // Instead of manual calculations, we use the hitbox's absolute bounding box.
  // This is a more robust method provided by the Flame engine.
  final playerHitbox = player.hitbox;
  final playerRect = playerHitbox.toAbsoluteRect();

  // The block is also a PositionComponent, so we can get its absolute bounding box.
  final blockRect = block.toAbsoluteRect();

  // The 'overlaps' method reliably checks for any intersection between the two rectangles.
  return playerRect.overlaps(blockRect);
}