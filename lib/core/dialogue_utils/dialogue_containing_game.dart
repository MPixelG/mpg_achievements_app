
import 'package:flame/game.dart';
import 'dialogue_character.dart';

mixin DialogueContainingGame on Game {
  bool get showingDialogue;
  set showingDialogue(bool val);

  // Finds a character component in the game world by its name.
  // This is a crucial link between your dialogue script and game objects.
  DialogueCharacter? findCharacterByName(String name);
}