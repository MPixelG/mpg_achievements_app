import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_yarn_creator.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

// State class for DialogueScreen that handles dialogue display and interaction
// Implements DialogueView mixin to integrate with the Jenny dialogue system
class DialogueScreenState extends State<DialogueScreen> with DialogueView {

  // Game instance reference for potential game state interactions
  late final PixelAdventure game;

  // Jenny dialogue system components
  late final YarnProject _project;        // Contains the compiled dialogue data
  late DialogueYarnCreator _yarnCreator;  // Helper class to load and create yarn projects
  late final _script;                     // Raw script content for debugging/display
  late DialogueRunner _dialogueRunner;    // Manages dialogue execution and flow

  // Current dialogue state
  DialogueLine? _currentLine;             // The currently displayed dialogue line
  bool _dialogueFinished = false;         // Flag to track if dialogue sequence is complete
  Completer<bool>? _finishedReadingCompleter; // Async completer to wait for user input

  @override
  void initState() {
    super.initState();
    // Initialize the dialogue system when the widget is created
    _loadYarnProject();
  }

  // Loads the Yarn project file and initializes the dialogue system
  Future<void> _loadYarnProject() async {
    // Create the yarn creator helper
    _yarnCreator = DialogueYarnCreator();

    // Load the yarn file from assets
    await _yarnCreator.loadYarnFile('assets/yarn/test.yarn');

    // Extract the compiled project and raw script
    _project = _yarnCreator.project;
    _script = _yarnCreator.script;

    // Create the dialogue runner with this widget as a dialogue view
    _dialogueRunner = DialogueRunner(
        yarnProject: _project,
        dialogueViews: [this]);

    // Start the dialogue from the 'Start' node
    _dialogueRunner.startDialogue('Start');

    // Debug print to verify project loading
    print(_project);
  }

  @override
  Widget build(BuildContext context) {
    // Get the current dialogue line
    final line = _currentLine;

    // If there's no current line, don't show anything
    if (line == null) {
      return SizedBox.shrink();
    }

    return Scaffold(
      // Transparent background so the game view remains visible underneath
      backgroundColor: Colors.transparent,

      // Stack allows us to layer the dialogue UI over the game
      body: Stack(
        children: [
          // Show Script button positioned in the upper left corner
          Positioned(
            top: 20,     // Distance from top of screen (accounting for status bar)
            left: 20,    // Distance from left edge
            child: FloatingActionButton.small(
              onPressed: _showScript,
              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              tooltip: 'Show Script',
              child: const Icon(Icons.code, size: 20), // Accessibility tooltip
            ),
          ),

          Positioned(
            bottom: 50,     // Distance from top of screen (accounting for status bar)
            right: 50,   // Distance from right edge
            child: CloseButton(),
            ),

          // Main dialogue UI positioned at the bottom center
          Positioned(
            left: 20,    // Left margin for dialogue box
            right: 20,   // Right margin for dialogue box
            bottom: 40,  // Distance from bottom of screen
            child: Opacity(
              opacity: 0.5, // Semi-transparent dialogue box for game visibility

              child: Card(
                // Use theme colors for consistent styling
                color: Theme.of(context).colorScheme.inversePrimary,
                elevation: 4, // Drop shadow for depth
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Rounded corners for modern look
                ),

                // Internal padding for dialogue content
                child: Padding(
                  padding: const EdgeInsets.all(12.0),

                  // Column layout for dialogue elements
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Only take necessary vertical space
                    children: [

                      // Character name display (if available)
                      Text(
                        line.character?.name ?? '', // Show character name or empty string
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontFamily: "gameFont" // Custom font for game consistency
                        ),
                      ),

                      const SizedBox(height: 6), // Spacing between name and dialogue

                      // Main dialogue text
                      Text(
                        line.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14, // Readable size for dialogue
                          fontFamily: "gameFont", // Consistent game font
                        ),
                      ),

                      const SizedBox(height: 10), // Spacing before button

                      // Dynamic button display based on dialogue state
                      _dialogueFinished
                      // Close button when dialogue sequence is complete
                          ? FilledButton.icon(
                        onPressed: () => setState(() {
                          _dialogueFinished = false; // Reset dialogue state
                        }),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close',
                            style: TextStyle(fontSize: 14, fontFamily: "gameFont")),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 36), // Compact button size
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      )
                      // Next button when waiting for user to continue reading
                          : (_finishedReadingCompleter != null
                          ? FilledButton.icon(
                        onPressed: _finishedReadingLine, // Continue to next line
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Next',
                            style: TextStyle(fontSize: 14, fontFamily: "gameFont")),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      )
                      // No button when dialogue is processing
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }




  // Called when a new dialogue line should be displayed
  // Returns a Future<bool> that completes when the user is ready to continue
  @override
  Future<bool> onLineStart(DialogueLine line) {
    // Ensure we don't have multiple completers active
    assert(_finishedReadingCompleter == null);

    // Create a new completer to wait for user input
    final completer = Completer<bool>();

    // Update the UI to show the new dialogue line
    setState(() {
      _currentLine = line;
    });

    // Store the completer so the Next button can complete it
    _finishedReadingCompleter = completer;

    // Return the future that will be completed when user clicks Next
    return completer.future;
  }

  // Called when the dialogue system needs to present choices to the player
  // Returns the index of the selected choice
  @override
  Future<int?> onChoiceStart(DialogueChoice choice) async {
    final completer = Completer<int>();

    // Show a modal bottom sheet with choice options
    showModalBottomSheet(
      context: context,
      isDismissible: false, // Force user to make a choice
      builder: (context) {
        return Container(

          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10,width: 2),
            borderRadius: BorderRadius.circular(15),
            color: Colors.cyanAccent, // Distinctive color for choices
          ),
          child: Column(
            spacing: 20,
            children: [
              // Create a button for each choice option
              for (final (index, option) in choice.options.indexed)
                OutlinedButton(
                  // Only enable button if the choice is available
                  onPressed: option.isAvailable
                      ? () {
                    // Complete with the selected choice index
                    completer.complete(index);
                    Navigator.pop(context); // Close the modal
                  }
                      : null, // Disabled if choice is not available
                  child: Text(option.text, style: TextStyle(fontSize: 12, fontFamily: "gameFont")),
                )
            ],
          ),
        );
      },
    );

    // Return the future that completes with the chosen option index
    return completer.future;
  }

  // Called when the entire dialogue sequence is finished
  @override
  FutureOr<void> onDialogueFinish() {
    setState(() {
      _dialogueFinished = true; // Mark dialogue as complete
      // Notify the parent widget that dialogue has finished
      widget.onDialogueFinished();
    });
  }

  // Shows a debug dialog displaying the raw script content
  // Useful for development and debugging dialogue scripts
  Future<void> _showScript() async {
    // Safety check to ensure widget is still mounted
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text('Script Content'),
        contentPadding: const EdgeInsets.all(24),
        children: [
          // Display the raw script in a scrollable container
          Container(
            constraints: BoxConstraints(
              maxHeight: 400, // Limit height for long scripts
              maxWidth: 300,  // Limit width for readability
            ),
            child: SingleChildScrollView(
              child: Text(
                _script,
                style: TextStyle(
                  fontFamily: 'monospace', // Monospace font for code readability
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Close button for the dialog
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CloseButton(),

            ],
          ),
        ],
      ),
    );
  }

  // Completes the current line reading and moves to the next dialogue element
  // Called when user clicks the Next button
  void _finishedReadingLine() {
    // Get the current completer (should never be null when this is called)
    final completer = _finishedReadingCompleter!;

    // Complete the future with true (indicating successful read)
    completer.complete(true);

    // Clear the completer and update UI
    setState(() {
      _finishedReadingCompleter = null;
    });
  }
}