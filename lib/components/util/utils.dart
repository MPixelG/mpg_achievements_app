//utils are helper_methods that check additional physical requirements in the game

//is our player overlapping an object in our world
//hitbox is defined in player.dart, here we need to update our borders for our collision

import 'package:mpg_achievements_app/components/player.dart';

import '../physics/collision_block.dart';

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

double abs(double val) => val < 0 ? -val : val;