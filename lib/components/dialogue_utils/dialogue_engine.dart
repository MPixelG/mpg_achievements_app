import 'dart:async'; // Required for async operations and the Completer class.
import 'package:flutter/material.dart'; // Flutter's material design widget library.
import 'package:jenny/jenny.dart'; // The core Jenny dialogue engine library.
// The following are project-specific imports and may vary.
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_yarn_creator.dart';

// Manages the state for the [DialogueScreen] widget.
//
// This class is responsible for:
// - Loading and running Yarn dialogue scripts using the Jenny library.
// - Displaying dialogue lines, character names, and choices.
// - Handling user input to advance the dialogue or make choices.
// - Providing a debug view for the raw Yarn script.
//
// It uses the `with DialogueView` mixin to register itself as a listener
// to the Jenny `DialogueRunner`, allowing it to respond to dialogue events
// like `onLineStart`, `onChoiceStart`, and `onDialogueFinish`.

class DialogueScreenState extends State<DialogueScreen> with DialogueView {

  // General layout and positioning constants.
  static const EdgeInsets _dialogueCardPadding = EdgeInsets.all(16.0);
  static const double _dialogueCardOpacity = 0.85;
  static final BorderRadius _dialogueBorderRadius = BorderRadius.circular(16.0);
  static const double _buttonSpacing = 16.0;
  static const double _outerPadding = 20.0;

  // Typography definitions. Using a getter `=>` allows access to `context`.
  static const String _gameFont = "gameFont";
  TextStyle get _characterNameStyle =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
        fontFamily: _gameFont,
        fontWeight: FontWeight.bold,
      );
  TextStyle get _dialogueTextStyle =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontFamily: _gameFont,
      );
  TextStyle get _buttonTextStyle => const TextStyle(fontFamily: _gameFont);

  // Color definitions. Using getters allows theme-dependent color resolution.
  Color get _dialogueCardColor => Theme.of(context).colorScheme.inversePrimary;
  Color get _scriptButtonColor =>
      Theme.of(context).colorScheme.secondary.withAlpha((255*0.8).round());
  Color get _choiceSheetColor => Colors.blueGrey.shade800;


  // region State Variables
  // These variables hold the state of the dialogue system at any given time.


  // The compiled Yarn project containing all nodes, lines, and commands.
  late final YarnProject _project;

  // The raw string content of the loaded .yarn file, used for the script viewer.
  late final String _rawYarnScript;

  // The Jenny engine instance that executes the dialogue logic.
  late DialogueRunner? _dialogueRunner;

  //A completer that pauses the [DialogueRunner].
  //
  // When `onLineStart` is called, a new completer is created. The runner
  // waits until `completer.complete()` is called, which happens when the user
  // clicks the "Next" button.

  Completer<bool>? _lineCompleter;

  // The current [DialogueLine] being displayed to the user.
  // If `null`, the dialogue UI is hidden.
  DialogueLine? _currentLine;

  // A flag indicating whether the entire dialogue sequence has finished.
  // When `true`, a "Close" button is shown instead of a "Next" button.
  bool _isDialogueFinished = false;


  // region Widget Lifecycle

  @override
  void initState() {
    super.initState();
    // Start the process of loading the Yarn file and setting up the dialogue runner.
    _initializeDialogue();
  }

  /// Asynchronously loads the Yarn file from assets, compiles it, and
  /// initializes the [DialogueRunner].
  Future<void> _initializeDialogue() async {
    // Helper class to load and parse the .yarn file.
    final yarnCreator = DialogueYarnCreator();
    await yarnCreator.loadYarnFile('assets/yarn/test.yarn');

    // Store the compiled project and the raw script text.
    _project = yarnCreator.project;
    _rawYarnScript = yarnCreator.script;

    // Create the DialogueRunner, providing it with the project and a
    // list of views. `[this]` means this class will handle UI events.
    _dialogueRunner = DialogueRunner(yarnProject: _project, dialogueViews: [this]);

    // Start the dialogue from the node named 'Start'.
    _dialogueRunner?.startDialogue('Start');
  }

  @override
  Widget build(BuildContext context) {
    // If there is no current line, it means the dialogue is not active or has
    // been closed. We return an empty, zero-sized widget.
    if (_currentLine == null) {
      return const SizedBox.shrink();
    }

    // The main UI is a Scaffold with a transparent background to allow the
    // game behind it to be visible.
    return Scaffold(
      backgroundColor: Colors.transparent,
      // A Stack allows us to layer widgets on top of each other, perfect for
      // an overlay UI like a dialogue screen.
      body: Stack(
        children: [
          _buildShowScriptButton(),
          Positioned(
            top: _outerPadding,
            right: _outerPadding,
            child: FloatingActionButton.small(
              onPressed: _closeDialogue,
              backgroundColor: _scriptButtonColor,
              tooltip: 'Close Dialogue',
              child: const Icon(Icons.close,size:20),
              ),
          ),
      _buildDialogueCard(_currentLine!),

         ],
      ),
    );
  }


  // region Widget Builder Methods
  // These methods break down the UI into smaller, manageable pieces.


  // Builds the small floating button used to display the raw script.
  Widget _buildShowScriptButton() {
    return Positioned(
      top: _outerPadding,
      left: _outerPadding,
      child: FloatingActionButton.small(
        onPressed: _showScript,
        backgroundColor: _scriptButtonColor,
        tooltip: 'Show Script',
        child: const Icon(Icons.code, size: 20),
      ),
    );
  }

  /// Builds the main card that displays the character name and dialogue text.
  Widget _buildDialogueCard(DialogueLine line) {
    return Positioned(
      left: _outerPadding,
      right: _outerPadding,
      bottom: _outerPadding + 20,
      child: Opacity(
        opacity: _dialogueCardOpacity,
        child: Card(
          color: _dialogueCardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: _dialogueBorderRadius),
          child: Padding(
            padding: _dialogueCardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min, // The card should only be as tall as its content.
              children: [
                // Display the character's name, or an empty string if none.
                Text(line.character?.name ?? '', style: _characterNameStyle),
                const SizedBox(height: 8),
                // Display the actual dialogue text.
                Text(line.text, textAlign: TextAlign.center, style: _dialogueTextStyle),
                const SizedBox(height: _buttonSpacing),
                // This method will decide whether to show a "Next" or "Close" button.
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Builds the primary action button based on the current dialogue state.
  Widget _buildActionButton() {
    // If the dialogue sequence is completely finished, show a "Close" button.
    if (_isDialogueFinished) {
      return FilledButton.icon(
        onPressed: _closeDialogue,
        icon: const Icon(Icons.close, size: 18),
        label: Text('Close', style: _buttonTextStyle),
      );
    }

    // If we are waiting for the user to advance the line, show a "Next" button.
    // `_lineCompleter` is not null only when `onLineStart` has been called and
    // `_advanceDialogue` has not yet been called.
    if (_lineCompleter != null) {
      return FilledButton.icon(
        onPressed: _advanceDialogue,
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: Text('Next', style: _buttonTextStyle),
      );
    }

    // If neither of the above, it means the runner is processing. Show nothing.
    return const SizedBox.shrink();
  }


  // region DialogueView Implementation
  // These methods are called by the `DialogueRunner` to interact with the UI.


  @override
  Future<bool> onLineStart(DialogueLine line) {
    // Create a new completer. The DialogueRunner will `await` this completer's future.
    final completer = Completer<bool>();

    // Update the state to display the new line and store the completer.
    // `setState` triggers a rebuild, showing the new text and the "Next" button.
    setState(() {
      _currentLine = line;
      _isDialogueFinished = false; // A new line means the dialogue is not finished.
      _lineCompleter = completer;
    });

    // Return the future. The runner is now paused.
    return completer.future;
  }

  @override
  Future<int?> onChoiceStart(DialogueChoice choice) {
    final completer = Completer<int>();

    // Use a ModalBottomSheet to display the choices to the user.
    // This sheet appears from the bottom of the screen.
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false, // The user must make a choice to proceed.
      backgroundColor: Colors.transparent, // Allows our custom container to define the look.
      builder: (context) => _buildChoiceSheet(choice, completer),
    );

    // Return the completer's future. The runner will await the user's choice.
    return completer.future;
  }

  @override
  void onDialogueFinish() {
    // The DialogueRunner has finished all nodes in the conversation.

    setState(() {
      widget.onDialogueFinished();
      // Mark the dialogue as finished to show the "Close" button.
      _isDialogueFinished = true;

    });
  }


  // region UI Actions and Helpers
  // Methods called in response to user interaction (button presses).


  // Hides the entire dialogue UI and resets its visible state.
  void _closeDialogue() {
    setState(() {
      _isDialogueFinished = false;
      widget.onDialogueFinished();
    });
  }

  // Signals to the DialogueRunner that the user has finished reading the line.
  void _advanceDialogue() {
    // Check if the completer is valid and has not already been completed.
    if (_lineCompleter != null && !_lineCompleter!.isCompleted) {
      // Complete the future. This unpauses the DialogueRunner.
      _lineCompleter!.complete(true);

      // Set the completer to null and rebuild to hide the "Next" button while
      // the runner processes the next step.
      setState(() {
        _lineCompleter = null;
      });
    }
  }

  // Shows a debug dialog displaying the raw content of the Yarn script.
  Future<void> _showScript() async {
    // Ensure the widget is still in the tree before showing a dialog.
    if (!mounted) return;

    //pause game
    widget.game.pauseEngine();

    await showDialog<void>(
      context: context,
      // The builder provides a `dialogContext` which is crucial for closing.
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Script Content'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
            child: SingleChildScrollView(
              child: Text(_rawYarnScript, style: const TextStyle(fontFamily: 'monospace')),
            ),
          ),
          const SizedBox(height: _buttonSpacing),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              // Using `dialogContext` ensures we only pop the dialog itself,
              // not the entire dialogue screen or game view.
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );

    if(mounted) {
      // Resume the game engine after the dialog is closed.
      widget.game.resumeEngine();
    }
  }

  // Builds the UI for the modal sheet that displays choices.
  Widget _buildChoiceSheet(DialogueChoice choice, Completer<int> completer) {
    return Container(
      padding: _dialogueCardPadding,
      margin: const EdgeInsets.all(_outerPadding),
      decoration: BoxDecoration(
        color: _choiceSheetColor,
        borderRadius: _dialogueBorderRadius,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create a button for each option in the choice.
          for (final (index, option) in choice.options.indexed) ...[
            OutlinedButton(
              // A choice can be unavailable if its condition (e.g., `<<if $seen_key>>`) is false.
              onPressed: option.isAvailable
                  ? () {
                // Complete the future with the index of the chosen option.
                completer.complete(index);
                // Close the bottom sheet.
                Navigator.pop(context);
              }
                  : null, // `null` onPressed disables the button.
              child: Text(option.text, style: _buttonTextStyle),
            ),
            // Add spacing between buttons, but not after the last one.
            if (index < choice.options.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}