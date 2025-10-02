//utils are helper_methods that check additional physical requirements in the game

//is our player overlapping an object in our world
//hitbox is defined in player.dart, here we need to update our borders for our collision

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../level_components/entity/player.dart';
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
  final playerRect = playerHitbox!.toAbsoluteRect();

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

Future<Vector2> getTilesizeOfLevel(String levelName) async {
  String content = await rootBundle.loadString('assets/tiles/$levelName.tmx');
  List<String> lines = content.split('\n');

  int indexOfTilesizeWidthDeclaration =
      lines[1].indexOf("tilewidth=\"") +
      11; //include the length of 'tilewidh="'
  int indexOfTilesizeHeightDeclaration =
      lines[1].indexOf("tileheight=\"") +
      12; //include the length of 'tileheight="'

  int indexOfNextSemicolonWidth = lines[1].indexOf(
    "\"",
    indexOfTilesizeWidthDeclaration,
  );
  int indexOfNextSemicolonHeight = lines[1].indexOf(
    "\"",
    indexOfTilesizeHeightDeclaration,
  );

  String tilesizeWidthString = lines[1].substring(
    indexOfTilesizeWidthDeclaration,
    indexOfNextSemicolonWidth,
  );
  String tilesizeHeightString = lines[1].substring(
    indexOfTilesizeHeightDeclaration,
    indexOfNextSemicolonHeight,
  );

  print("width: $tilesizeWidthString ($indexOfNextSemicolonWidth)");
  print("height: $tilesizeHeightString ($indexOfNextSemicolonHeight)");

  return Vector2(
    double.parse(tilesizeWidthString),
    double.parse(tilesizeHeightString),
  );
}

num max<T extends num>(List<T> vals) {
  T? smallestVal;
  for (var value in vals) {
    if (smallestVal == null || value < smallestVal) smallestVal = value;
  }

  return smallestVal ?? 0;
}

Future<String> getOrientationOfLevel(String levelName) async {
  String content = await rootBundle.loadString('assets/tiles/$levelName.tmx');
  List<String> lines = content.split('\n');

  int indexOfOrientationDeclaration =
      lines[1].indexOf("orientation=\"") +
      13; //include the length of 'orientation="'
  int indexOfNextSemicolon = lines[1].indexOf(
    "\"",
    indexOfOrientationDeclaration,
  );

  return lines[1].substring(
    indexOfOrientationDeclaration,
    indexOfNextSemicolon,
  );
}

Vector2 orthogonalToIsometric(Vector2 ortho) {
  return Vector2(ortho.x - ortho.y, (ortho.x + ortho.y) / 2);
}

///takes 2 strings and returns a value between 0 and 1, representing the similarity of the 2 strings.
double jaro(String s1, String s2) {
  if (s1 == s2) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  s1 = s1.toLowerCase();
  s2 = s2.toLowerCase();

  final List<int> a = s1.codeUnits;
  final List<int> b = s2.codeUnits;
  final int len1 = a.length;
  final int len2 = b.length;

  final int matchDistance = ((len1 > len2 ? len1 : len2) ~/ 2) - 1;
  final List<bool> matched1 = List<bool>.filled(len1, false);
  final List<bool> matched2 = List<bool>.filled(len2, false);

  int matches = 0;
  for (int i = 0; i < len1; i++) {
    final int start = (i - matchDistance).clamp(0, len2 - 1);
    final int end = (i + matchDistance).clamp(0, len2 - 1);
    for (int j = start; j <= end; j++) {
      if (!matched2[j] && a[i] == b[j]) {
        matched1[i] = true;
        matched2[j] = true;
        matches++;
        break;
      }
    }
  }

  if (matches == 0) return 0.0;

  int transpositions = 0;
  int k = 0;
  for (int i = 0; i < len1; i++) {
    if (!matched1[i]) continue;
    while (!matched2[k]) k++;
    if (a[i] != b[k]) transpositions++;
    k++;
  }

  final double m = matches.toDouble();
  final double t = transpositions / 2.0;

  return ((m / len1) + (m / len2) + ((m - t) / m)) / 3.0;
}

///an upgraded version of [jaro], also considering typos
double jaroWinkler(
  String s1,
  String s2, {
  double prefixScale = 0.1,
  int maxPrefix = 4,
}) {
  final double j = jaro(s1, s2);
  if (j == 0.0) return 0.0;

  int prefix = 0;
  final int limit = s1.length < s2.length ? s1.length : s2.length;
  for (int i = 0; i < limit && i < maxPrefix; i++) {
    if (s1[i] == s2[i])
      prefix++;
    else
      break;
  }

  return j + (prefix * prefixScale * (1.0 - j));
}

Future<File> saveImage(ui.Image image, String filename) async {
  final directory = await Directory.systemTemp.createTemp();
  final file = File('${directory.path}/$filename');

  return file.writeAsBytes(
    (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asInt8List(),
    flush: true,
  );
}

//Check OS for Joystick support

//check which platform is used and if the touch controls must be shown, TODO right settings must be set here
bool shouldShowJoystick() {
  return defaultTargetPlatform.name.contains(RegExp("android|iOS|fuchsia"));
}
