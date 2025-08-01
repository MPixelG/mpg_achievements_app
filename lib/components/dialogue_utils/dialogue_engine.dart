
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
  late final DialogueYarnCreator yarnCreator;
  late final _script;
  late DialogueRunner _dialogueRunner;
  DialogueLine? _currentLine;
  bool _dialogueFinished = false;
  Completer<bool>? _finishedReadingCompleter;

  @override
  void initState(){
    super.initState();
    _loadYarnProject();


  }

  Future<void> _loadYarnProject() async {
    _project = await yarnCreator.yarn_project;
    _dialogueRunner = DialogueRunner(
        yarnProject: _project,
        dialogueViews: [this]);
    _script = await yarnCreator.script;
    _dialogueRunner.startDialogue('Start');

      }

  @override
  Widget build(BuildContext context) {
    final line = _currentLine;
    if (line == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Loading...',
            style: Theme
                .of(context)
                .textTheme
                .displayMedium,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text(game.platform),
        actions: [
          FilledButton(onPressed: _showScript,
            child: Text('ShowYarnScript'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: <Widget>[
              Text(line.character?.name ?? ''),
              Card(
                color: Theme
                    .of(context)
                    .colorScheme
                    .inversePrimary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: Theme
                        .of(context)
                        .textTheme
                        .headlineMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _dialogueFinished ? FilledButton.icon(
        onPressed: () =>
            setState(() {
              _dialogueFinished = false;
            }),
        icon: Icon(Icons.close),
        label: Text('Close'),
      )
          : (_finishedReadingCompleter != null
          ? FilledButton.icon(
        onPressed: _finishedReadingLine,
        icon: Icon(Icons.arrow_forward),
        label: Text('Next'),
      )
          : null),
    );
  }



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
    });

  }

   Future<void> _showScript() async {

    _script = await _getScript(_project);
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

  Future<String> _getScript(YarnProject yarn) {

    return yarnCreator.yarnpath;


  }

  void _finishedReadingLine() {
    final completer = _finishedReadingCompleter!;
    completer.complete(true);
    setState(() {
      _finishedReadingCompleter = null;
    });


  }
}

