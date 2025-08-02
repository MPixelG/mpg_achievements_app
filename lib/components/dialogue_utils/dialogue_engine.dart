
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/GUI/menus.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_screen.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/dialogue_yarn_creator.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class DialogueScreenState extends State<DialogueScreen> with DialogueView {

  late final PixelAdventure game;
  late final YarnProject _project;
  late DialogueYarnCreator _yarnCreator;
  late final _script;
  late DialogueRunner _dialogueRunner;
  DialogueLine? _currentLine;
  bool _dialogueFinished = false;
  Completer<bool>? _finishedReadingCompleter;

  @override
  void initState() {
    super.initState();
    _loadYarnProject();

  }

  Future<void> _loadYarnProject() async {
    _yarnCreator = DialogueYarnCreator();
    await _yarnCreator.loadYarnFile('assets/yarn/test.yarn');
    _project = _yarnCreator.project;
    _script = _yarnCreator.script;
    _dialogueRunner = DialogueRunner(
        yarnProject: _project,
        dialogueViews: [this]);
    _dialogueRunner.startDialogue('Start');
    print(_project);
  }

  @override
  Widget build(BuildContext context) {
    final line = _currentLine;
    if (line == null) {
      return SizedBox.shrink();
    }

    return Scaffold(
      // We make the background transparent so the overlay doesn't block the game view
      backgroundColor: Colors.transparent,

      // Stack allows layering widgets — we'll place the semi-transparent background and the dialogue box on top
      body: Stack(
        children: [
         // Dialogue UI, positioned at the bottom center with some horizontal padding
          Positioned(
            left: 20,    // Left padding
            right: 20,   // Right padding
            bottom: 40,  // Distance from the bottom of the screen
            child: Opacity(
              opacity: 0.5, // The whole dialogue box is 50% transparent

              child: Card(
                color: Theme.of(context).colorScheme.inversePrimary, // Use theme color for styling
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // Rounded corners
                ),

                // Padding inside the card for its content
                child: Padding(
                  padding: const EdgeInsets.all(12.0),

                  // This Column holds the character name, dialogue text, and button
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Only take up as much space as needed
                    children: [

                      // Character name (if available)
                      Text(
                        line.character?.name ?? '',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontFamily: "gameFont"),
                      ),

                      const SizedBox(height: 6),

                      // Main dialogue line text
                      Text(
                        line.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14, // Slightly smaller text
                          fontFamily: "gameFont",
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Show different buttons depending on dialogue state
                      _dialogueFinished
                      // Show a 'Close' button when the dialogue is finished
                          ? FilledButton.icon(
                        onPressed: () => setState(() {
                          _dialogueFinished = false;
                        }),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close', style: TextStyle(fontSize: 14, fontFamily: "gameFont")),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 36), // Small button
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      )
                          : (_finishedReadingCompleter != null
                      // Show a 'Next' button if we're waiting for the player to finish reading
                          ? FilledButton.icon(
                        onPressed: _finishedReadingLine,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Next', style: TextStyle(fontSize: 14, fontFamily: "gameFont")),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      )
                          : const SizedBox.shrink()), // No button if there's no completer
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

Future<String> _getscript() =>  DefaultAssetBundle.of(context).loadString('assets/yarn/test.yarn');


  //part which is implemented in DialogueView mixin
  @override
  Future<bool> onLineStart(DialogueLine line){

    assert(_finishedReadingCompleter == null);
    final completer = Completer<bool>();


    setState(() {
      _currentLine = line;
          });

    _finishedReadingCompleter = completer;
    return completer.future;

  }

  @override
  Future<int?> onChoiceStart(DialogueChoice choice)async {
    final completer = Completer<int>();
    //widget which is shown. Potentially this can be filled with our Widgetbuilder
    showModalBottomSheet(context: context,
      isDismissible: false,
      builder: (context){
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.cyanAccent), //borderRadius: BorderRadius.circular(12),
          child: Column(
            spacing: 20,
            children: [for(final (index,option) in choice.options.indexed)
              OutlinedButton(onPressed: option.isAvailable ?
                  (){
                completer.complete(index);
                Navigator.pop(context);}
                  : null,
                child: Text(option.text),
              )
            ],
          ),
        );
      },
    );

    return completer.future;
  }


  @override
  FutureOr<void> onDialogueFinish(){
    setState((){
      _dialogueFinished = true;
      // Notify the parent that dialogue is finished
      widget.onDialogueFinished();
    });

  }

   Future<void> _showScript() async {

    if (!mounted) return;
    showDialog(
        context: context,
        builder: (_) => SimpleDialog(
          title: Text('Test'),
          contentPadding: const EdgeInsets.all(24),
          children: [
            Text(_script),
            FilledButton(
                onPressed: () => Text('test'),
                child: Text('pressed!')),
            CloseButton(),
          ],
        ),
    );
  }

  void _finishedReadingLine() {
    final completer = _finishedReadingCompleter!;
    completer.complete(true);
    setState(() {
      _finishedReadingCompleter = null;
    });


  }
}

