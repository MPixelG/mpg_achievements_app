//utils are helper_methods that check additional physical requirements in the game

//is our player overlapping an object in our world
//hitbox is defined in player.dart, here we need to update our borders for our collision

import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/player.dart';
import '../physics/collision_block.dart';

/* Checks whether a player's hitbox is colliding with a given collision block.
This function uses Flame's built-in methods to convert both the player's hitbox
and the block into absolute rectangles (Rect), and checks if those rectangles overlap.
Returns `true` if a collision is detected, otherwise `false`.*/

bool checkCollision(Player player, CollisionBlock block) {
  /* Instead of manual calculations, we use the hitbox's absolute bounding box.
  // This is a more robust method provided by the Flame engine.
  // Get the player's hitbox component.
  This is typically a ShapeHitbox (e.g., RectangleHitbox) added to the player.*/
  final playerHitbox = player.hitbox;

  /* Convert the player's hitbox to its absolute rectangular bounds in the game world.
  `toAbsoluteRect()` takes into account the component's position and anchor.*/
  final playerRect = playerHitbox.toAbsoluteRect();

  /* The block is also a PositionComponent, so we can get its absolute bounding box.
  Convert the block (also a PositionComponent) to its absolute rectangle.
  This accounts for its size, position, and any parent transformations.
   */
  final blockRect = block.toAbsoluteRect();

  // The 'overlaps' method reliably checks for any intersection between the two rectangles.
  return playerRect.overlaps(blockRect);
}

//A simple utility function that returns the absolute (positive) value of a number.
double abs(double val) => val < 0 ? -val : val;

// Recursively prints the game component tree starting from a given root component.
// Useful for debugging the structure of your Flame game's scene graph.
void printGameTree(
  Component component, [
  int depth = 0,
  String prefix = "",
  String childrenPrefix = "",
]) {
  // Get the name/type of the current component.
  final name = component.runtimeType.toString();

  // Use the component's hash code as a unique identifier for debugging.
  final id = component.hashCode;

  // Print the current component's info with indentation.
  // Output example: "  - SpriteComponent (12345678)"
  print('$prefix$name ($id)');

  // Iterate over the component's children, if any.
  // Flame components always have a children list, even if it's empty.
  int childIndex = 0; //the index of the child that is currently being worked on
  final int totalChildIndexes = component
      .children
      .length; //the total amound of child nodes in the component
  for (final child in component.children) {
    // Recursively call this function for each child, increasing the depth.
    // Each level deeper in the tree adds two spaces for visual clarity.
    if (childIndex + 1 == totalChildIndexes) {
      //if its the final child in the component, we use └── bc its the end of that branch
      printGameTree(
        child,
        depth + 1,
        "$childrenPrefix└── ",
        "$childrenPrefix└── ",
      );
    } else {
      printGameTree(
        child,
        depth + 1,
        "$childrenPrefix├── ",
        "$childrenPrefix│   ",
      ); //use │ to indicate, that the 2 branches arent connected
    }
    childIndex++; //increase the child index
  }
}

Vector2 safeNormalize(Vector2 vector) {
  final length = vector.length;
  if (length == 0) return Vector2.zero();
  return vector / length;
}


Future<int> getTilesizeOfLevel(String levelName) async{

  String content = await rootBundle.loadString('assets/tiles/$levelName.tmx');
  List<String> lines = content.split('\n');

  int indexOfTilesizeDeclaration = lines[1].indexOf("tilewidth=\"") + 11; //include the length of 'tilewidh="'

  int indexOfNextSemicolon = lines[1].indexOf("\"", indexOfTilesizeDeclaration);

  String tilesizeString = lines[1].substring(indexOfTilesizeDeclaration, indexOfNextSemicolon);


  return int.parse(tilesizeString);
}

