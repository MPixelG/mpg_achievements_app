// lib/managers/conversation_manager.dart

import 'dart:async';
import 'package:flame/components.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/yarn_creator.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ConversationManager with DialogueView {
  final PixelAdventure game;
  // The Jenny engine instance that executes the dialogue logic.
  //A completer that pauses the [DialogueRunner].
  // When `onLineStart` is called, a new completer is created. The runner
  // waits until `completer.complete()` is called, which happens when the user
  // clicks the "Next" button.
  // The current [DialogueLine] being displayed to the user.
  // If `null`, the dialogue UI is hidden.
  late final DialogueRunner _dialogueRunner;
  Completer<void>? _lineCompleter;
  DialogueLine? _currentLine;
  Completer<int>? _choiceCompleter;
  DialogueChoice? _currentChoice;
  //variables for YarnEngine
  // The compiled Yarn project containing all nodes, lines, and commands.
  late final YarnProject _project;
  // The raw string content of the loaded .yarn file, used for the script viewer.
  late final String _rawYarnScript;
  // A flag indicating whether the entire dialogue sequence has finished.
  // When `true`close conversation
  final bool _isConversationFinished = false;
  // Tracks the currently active speech bubble overlay key for each character.
  // This allows us to remove the correct bubble when a character speaks again.
  final Map<String, String> _activeSpeechBubbles = {};

  ConversationManager({required this.game});

  /// Starts a new conversation from a given Yarn script.
  Future<void> startConversation(String yarnFilePath) async {
    // Clear any bubbles from a previous conversation
    _clearAllSpeechBubbles();

    // Load and parse the Yarn script
    // NOTE: This assumes you have a way to load file content.
    // In Flame, you might use `Flame.assets.readFile(yarnFilePath)`
    final yarnCreator = YarnCreator(yarnFilePath, commands: {});
    await yarnCreator.loadYarnFile();
    final yarnProject = yarnCreator.project;

    _dialogueRunner = DialogueRunner(
      yarnProject: yarnProject,
      dialogueViews: [this],
    );

    // Start the dialogue from the 'Start' node
    _dialogueRunner.startDialogue('Start');
  }

  @override
  Future<void> onLineStart(DialogueLine line) async {
    _lineCompleter = Completer<void>();

    // Determine who is speaking. Default to 'Player' if no character is specified.
    // Your Yarn script should have lines like "Player: Hello!" or "Guard: Halt!".
    final characterName = line.character ?? 'Player';
    final character = _findCharacterByName(characterName);

    if (character == null) {
      print("Error: Character '$characterName' not found in the game world.");
      // Immediately complete to avoid getting stuck
      _lineCompleter?.complete();
      return;
    }

    // Remove the previous speech bubble for this character, if one exists.
    _removeSpeechBubbleFor(characterName);

    // Create a new, unique overlay key for this bubble.
    final overlayKey = 'SpeechBubble_${characterName}_${DateTime.now().millisecondsSinceEpoch}';
    _activeSpeechBubbles[characterName] = overlayKey;

    game.overlays.add(
      overlayKey,
          (context, game) => SpeechBubble(
        // The SpeechBubble is now a simple presentation widget.
        game: this.game,
        character: character,
        text: line.text,
        onComplete: () {
          // When the typing animation finishes, we complete the future,
          // allowing the DialogueRunner to proceed to the next line.
          if (!(_lineCompleter?.isCompleted ?? true)) {
            _lineCompleter?.complete();
          }
        },
        onDismiss: () {
          game.overlays.remove(overlayKey);
          if (_activeSpeechBubbles[characterName] == overlayKey) {
            _activeSpeechBubbles.remove(characterName);
          }
        },
      ),
    );

    // Pause the dialogue runner until the line completer is finished.
    await _lineCompleter?.future;
  }

  @override
  Future<int> onChoiceStart(DialogueChoice choice) async {
    _choiceCompleter = Completer<int>();

    // Choices are always presented from the player's perspective.
    const characterName = 'Player';
    final player = _findCharacterByName(characterName);

    if (player == null) {
      print("Error: Player not found. Cannot show choices.");
      // Default to the first choice to avoid getting stuck.
      return 0;
    }

    // Remove the player's last line to make room for the choices bubble.
    _removeSpeechBubbleFor(characterName);

    final overlayKey = 'SpeechBubble_Choices_${DateTime.now().millisecondsSinceEpoch}';
    _activeSpeechBubbles[characterName] = overlayKey;

    game.overlays.add(
      overlayKey,
          (context, game) => SpeechBubble(
        game: this.game,
        character: player,
        text: '', // No text, only choices are shown
        choices: choice,
        onChoiceSelected: (selectedIndex) {
          if (!(_choiceCompleter?.isCompleted ?? true)) {
            _choiceCompleter?.complete(selectedIndex);
          }
          // Once a choice is made, the bubble is dismissed.
          game.overlays.remove(overlayKey);
        },
      ),
    );

    return _choiceCompleter!.future;
  }

  @override
  void onDialogueFinish() {
    print("Dialogue has finished.");
    _clearAllSpeechBubbles();
  }

  /// Finds a character component in the game world by its name.
  /// This is a crucial link between your dialogue script and game objects.
  Component? _findCharacterByName(String name) {
    // Case-insensitive comparison
    final lowerCaseName = name.toLowerCase();

    if (lowerCaseName == 'player') {
      return game.gameWorld.player;
    }

    // You need a way to access your NPCs. This example assumes they are
    // in a list on your `gameWorld` component.
    try {
      return game.gameWorld.npcs.firstWhere(
            (npc) => npc.name.toLowerCase() == lowerCaseName,
      );
    } catch (e) {
      return null; // Return null if no NPC with that name is found
    }
  }

  /// Removes the currently active speech bubble for a specific character.
  void _removeSpeechBubbleFor(String characterName) {
    if (_activeSpeechBubbles.containsKey(characterName)) {
      final oldOverlayKey = _activeSpeechBubbles.remove(characterName);
      if (oldOverlayKey != null) {
        game.overlays.remove(oldOverlayKey);
      }
    }
  }

  // Clears all speech bubbles managed by this instance.
  void _clearAllSpeechBubbles() {
    for (final key in _activeSpeechBubbles.values) {
      game.overlays.remove(key);
    }
    _activeSpeechBubbles.clear();
  }
}