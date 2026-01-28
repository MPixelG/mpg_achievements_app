import 'package:flame/game.dart' hide Vector3;
import 'package:vector_math/vector_math_64.dart';
import 'dialogue_character.dart';


mixin DialogueContainingGame on Game {
  bool get showingDialogue;
  set showingDialogue(bool val);

  // Finds a character component in the game world by its name.
  // This is a crucial link between your dialogue script and game objects.
  DialogueCharacter? findCharacterByName(String name);
  Future<Vector3?> calculateBubblePosition(Vector3? position);

}