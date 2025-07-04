//utils are helper_methods that check additional physical requirements in the game

//is our player overlapping an object in our world

bool checkCollision(player, block) {
  final playerX = player.position.x;
  final playerY = player.position.y;
  final playerWidth = player.width;
  final playerHeight = player.height;
  final blockX = block.x;
  final blockY = block.y;
  final blockWidth = block.width;
  final blockHeight = block.height;

  //we need to fix the x value because if we flip our character to the left the x value is still measured at the top right, so if we flip x-stays on the top left
  final fixedX = player.scale.x < 0 ? playerX - playerWidth : playerX;
  final fixedY = block.isPlatform ? playerY + playerHeight : playerY;

  //check if player is colliding e.g. if playerY (Top of Player) = bottom of player is smaller than blockY (Top of the block) + height which is the upside of a collisionblock then there is a collision
  return ( //does the top of our player touch the bottom of our obstacle
  fixedY < blockY + blockHeight &&
      //does the bottom of our player touch the top of our obstacle
      playerY + playerHeight > blockY
      // is the left of our player touching the right of our obstacle
      &&
      fixedX < blockX + blockWidth
      //is the right of our player touching the left of our obstacle
      &&
      fixedX + playerWidth > blockX);
}
