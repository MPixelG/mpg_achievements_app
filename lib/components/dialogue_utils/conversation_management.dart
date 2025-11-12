import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/yarn_creator.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/router/router.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class ConversationManager with DialogueView {
  final PixelAdventure game;
  // The Jenny engine instance that executes the dialogue logic.
  //A completer that pauses the [DialogueRunner].
  // When `onLineStart` is called, a new completer is created. The runner
  // waits until `completer.complete()` is called, which happens when the user
  // clicks the "Next" button.
  // The current [DialogueLine] being displayed to the user.
  // If `null`, the dialogue UI is hidden. Nullable to have more freedom over new conversations
  DialogueRunner? _dialogueRunner;
  Completer<void>? _lineCompleter;
  DialogueLine? _currentLine;
  Completer<int>? _choiceCompleter;
  DialogueChoice? _currentChoice;
  //variables for YarnEngine
  // The compiled Yarn project containing all nodes, lines, and commands.
  YarnProject? _project;
  // The raw string content of the loaded .yarn file, used for the script viewer.
  String? _rawYarnScript;
  // A flag indicating whether the entire dialogue sequence has finished.
  // When `true`close conversation
  final bool _isConversationFinished = false;
  late bool _showingScript = false;
  // Tracks the currently active speech bubble overlay key for each character.
  // This allows us to remove the correct bubble when a character speaks again.
  final Map<String, String> _activeSpeechBubbles = {};

  ConversationManager({required this.game});

  // Starts a new conversation from a given Yarn script.
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
      yarnProject: _project!,
      dialogueViews: [this],
    );

    // Start the dialogue from the node named 'Start'.
    unawaited(_dialogueRunner!.startDialogue('Start'));
  }

  @override
  Future<bool> onLineStart(DialogueLine line) async {
    _lineCompleter = Completer<void>();
    //get context from game, The BuildContext argument is your handle into the location of the widget in the widget tree. This location is used for looking up inherited widgets
    final BuildContext? _ = rootNavigatorKey.currentContext; //todo maybe GlobalKey<NavigatorState> for accessing BuildContext
    // Determine who is speaking. Default to 'Player' if no character is specified.
    // Your Yarn script should have lines like "Player: Hello!" or "Guard: Halt!".
    final String characterName = line.character?.name ?? 'Character';
    print("Speaking character:'$characterName'");
    final IsoPositionComponent? character = _findCharacterByName(characterName);
    print('found character:$character');
    // Add this check
    if (character == null) {
      print("Error: Character '$characterName' not found in game.npcs. Cannot show speech bubble.");
      // Complete the line immediately so dialogue doesn't hang
      _lineCompleter?.complete();
    return true;
    }
    // Remove the previous speech bubble for this character, if one exists.
    _removeSpeechBubbleFor(characterName);

    // Create a new, unique overlay key for this bubble.
    final overlayKey =
        'SpeechBubble_${characterName}_${DateTime.now().millisecondsSinceEpoch}';
    print('overlayKey1:$overlayKey');
    _activeSpeechBubbles[characterName] = overlayKey;


    game.overlays.addEntry(overlayKey, (_,game) =>
        SpeechBubble(
            component: character,
            text: line.text,
            game: this.game,
          onComplete: (){
              if (!(_lineCompleter!.isCompleted ?? true)){
                _lineCompleter!.complete();
              }
          },
          onDismiss: () => _removeSpeechBubbleFor(characterName),
        )
        );

    game.overlays.add(overlayKey);

    // Pause the dialogue runner until the line completer is finished.
    await _lineCompleter?.future;

    return true; //always true after completion
  }

  @override
  Future<int> onChoiceStart(DialogueChoice choice) async {
    _choiceCompleter = Completer<int>();

    final BuildContext? _ = rootNavigatorKey.currentContext; //todo maybe GlobalKey<NavigatorState> for accessing BuildContext

    // Choices are always presented from the player's perspective.
    const characterName = 'Player';
    final character = _findCharacterByName(characterName);
    print('characterChoice:$character');

    if (character == null) {
      print("Error: Character '$characterName' not found. Cannot show choices.");
      // Default to the first choice to avoid getting stuck.
      return 0;
    }

    // Remove the player's last line to make room for the choices bubble.
   // _removeSpeechBubbleFor(characterName);

    final String overlayKey =
        'SpeechBubble_Choices_${DateTime.now().millisecondsSinceEpoch}';
    _activeSpeechBubbles[characterName] = overlayKey;
    print('overlayKeyChoice:$overlayKey');

    game.overlays.addEntry(
      overlayKey,
          (_, game) => SpeechBubble(
        key: ValueKey(overlayKey),
        game: this.game,
        component: character,
        text: '', // No primary text, or you could add a prompt like "?"
        choices: choice, // Pass the DialogueChoice object
        onChoiceSelected: (int selectedIndex) {
          // This callback is triggered when a choice is pressed in the bubble
          _removeSpeechBubbleFor(characterName); // Remove the choice bubble
          if (!(_choiceCompleter?.isCompleted ?? true)) {
            _choiceCompleter?.complete(selectedIndex);
          }
        },
      ),
    );

    game.overlays.add(overlayKey);


    return _choiceCompleter!.future;
  }

  @override
  void onDialogueFinish() {
    print("Dialogue has finished.");
    _clearAllSpeechBubbles();
  }

  // Finds a character component in the game world by its name.
  // This is a crucial link between your dialogue script and game objects.
  IsoPositionComponent? _findCharacterByName(String name) {
    // Case-insensitive comparison
    final String lowerCaseName = name.toLowerCase();

    // You need a way to access your NPCs. This example assumes they are
    // in a list on your `gameWorld` component.
    return game.npcs[name]; }

  // Removes the currently active speech bubble for a specific character.
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
    const double buttonSpacing = 10;
    // Ensure the widget is still in the tree before showing a dialog.
    if (!_showingScript) return;

    _showingScript = true;
    //pause game
    game.pauseEngine();

    await showDialog<void>(
      context: game.buildContext!,
      // The builder provides a `dialogContext` which is crucial for closing.
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Script Content'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
            child: SingleChildScrollView(
              child: Text(
                _rawYarnScript!,
                style: const TextStyle(fontFamily: 'gameFont'),
              ),
            ),
          ),
          const SizedBox(height: buttonSpacing),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              // Using `dialogContext` ensures we only pop the dialog itself,
              // not the entire dialogue screen or game view.
              onPressed: () => {Navigator.of(dialogContext).pop(), _showingScript = false},
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );

    if (!_showingScript) {
      // Resume the game engine after the dialog is closed.
      game.resumeEngine();
    }
  }
}
