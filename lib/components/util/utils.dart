//utils are helper_methods that check additional physical requirements in the game

//is our player overlapping an object in our world
//hitbox is defined in player.dart, here we need to update our borders for our collision

import 'package:flame/components.dart';
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


/// Recursively prints the game component tree starting from a given root component.
/// Useful for debugging the structure of your Flame game's scene graph.
void printGameTree(Component component, [int depth = 0]) {
  // Create an indentation string based on the depth of the component in the tree.
  // Each level deeper in the tree adds two spaces for visual clarity.
  final indent = '  ' * depth;

  // Get the name/type of the current component.
  final name = component.runtimeType.toString();

  // Use the component's hash code as a unique identifier for debugging.
  final id = component.hashCode;

  // Print the current component's info with indentation.
  // Output example: "  - SpriteComponent (12345678)"
  print('$indent- $name ($id)');

  // Iterate over the component's children, if any.
  // Flame components always have a children list, even if it's empty.
  for (final child in component.children) {
    // Recursively call this function for each child, increasing the depth.
    printGameTree(child, depth + 1);
  }
}