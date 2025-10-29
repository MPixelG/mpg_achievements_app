import 'dart:async';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/yarn_creator.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
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
  late bool _showScript = false;
  // Tracks the currently active speech bubble overlay key for each character.
  // This allows us to remove the correct bubble when a character speaks again.
  final Map<String, String> _activeSpeechBubbles = {};

  ConversationManager({required this.game});

  /// Starts a new conversation from a given Yarn script.
  Future<void> startConversation(String yarnFilePath) async {
    // Clear any bubbles from a previous conversation
    _clearAllSpeechBubbles();
    // Helper class to load and parse the .yarn file.
    final yarnCreator = YarnCreator(
      yarnFilePath, // Use the path from the widget
      commands: {}, // Use the commands from the widget
    );
    await yarnCreator.loadYarnFile();

    // Store the compiled project and the raw script text.
    _project = yarnCreator.project;
    _rawYarnScript = yarnCreator.script;

    // Create the DialogueRunner, providing it with the project and a
    // list of views. `[this]` means this class will handle UI events. properties passed into the widget are used for yarnCreation
    _dialogueRunner = DialogueRunner(
      yarnProject: _project,
      dialogueViews: [this],
    );

    // Start the dialogue from the node named 'Start'.
    _dialogueRunner.startDialogue('Start');
  }

  Future<void> onLineSart(DialogueLine line) async {
    _lineCompleter = Completer<void>();

    // Determine who is speaking. Default to 'Player' if no character is specified.
    // Your Yarn script should have lines like "Player: Hello!" or "Guard: Halt!".
    final String characterName = line.character.toString() ?? 'Player';
    final IsoPositionComponent? character = _findCharacterByName(characterName);

    // Remove the previous speech bubble for this character, if one exists.
    _removeSpeechBubbleFor(characterName);

    // Create a new, unique overlay key for this bubble.
    final overlayKey =
        'SpeechBubble_${characterName}_${DateTime.now().millisecondsSinceEpoch}';
    _activeSpeechBubbles[characterName] = overlayKey;

    // Pause the dialogue runner until the line completer is finished.
    await _lineCompleter?.future;
    _removeSpeechBubbleFor(characterName);
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

    final String overlayKey =
        'SpeechBubble_Choices_${DateTime.now().millisecondsSinceEpoch}';
    _activeSpeechBubbles[characterName] = overlayKey;

    return _choiceCompleter!.future;
  }

  @override
  void onDialogueFinish() {
    print("Dialogue has finished.");
    _clearAllSpeechBubbles();
  }

  /// Finds a character component in the game world by its name.
  /// This is a crucial link between your dialogue script and game objects.
  IsoPositionComponent? _findCharacterByName(String name) {
    // Case-insensitive comparison
    final String lowerCaseName = name.toLowerCase();

    // You need a way to access your NPCs. This example assumes they are
    // in a list on your `gameWorld` component.
    try {
      return game.npcs.firstWhere(
        (npc) => npc.toString().toLowerCase() == lowerCaseName,
      );
    } catch (e) {
      return null; // Return null if no NPC with that name is found
    }
  }

  /// Removes the currently active speech bubble for a specific character.
  void _removeSpeechBubbleFor(String characterName) {
    if (_activeSpeechBubbles.containsKey(characterName)) {
      final String? oldOverlayKey = _activeSpeechBubbles.remove(characterName);
      game.overlays.remove(oldOverlayKey!);
    }
  }

  // Clears all speech bubbles managed by this instance.
  void _clearAllSpeechBubbles() {
    for (final key in _activeSpeechBubbles.values) {
      game.overlays.remove(key);
    }
    _activeSpeechBubbles.clear();
  }

  // Shows a debug dialog displaying the raw content of the Yarn script.
  Future<void> _showScript() async {
    late final double buttonSpacing = 10;
    // Ensure the widget is still in the tree before showing a dialog.
    if (!_showScript) return;

    _showScript = true;

    //pause game
    game.pauseEngine();

    /*await showDialog<void>(
      context: ,
      // The builder provides a `dialogContext` which is crucial for closing.
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Script Content'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
            child: SingleChildScrollView(
              child: Text(
                _rawYarnScript,
                style: const TextStyle(fontFamily: 'gameFont'),
              ),
            ),
          ),
          SizedBox(height: buttonSpacing),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              // Using `dialogContext` ensures we only pop the dialog itself,
              // not the entire dialogue screen or game view.
              onPressed: () => {Navigator.of(dialogContext).pop(), _showScript = false},
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );

    if (!_showScript) {
      // Resume the game engine after the dialog is closed.
      game.resumeEngine();
    }*/
  }
}
