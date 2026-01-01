import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../base_game.dart';
import 'dialogue_engine.dart';

class DialogueScreen extends ConsumerStatefulWidget {
  final VoidCallback onDialogueFinished;
  final BaseGame game;
  final String yarnFilePath;
  final Map<String, Function> commands;


  const DialogueScreen({
    super.key,
    required this.onDialogueFinished,
    required this.game,
    required this.yarnFilePath,
    this.commands = const{},
  });

  @override
  ConsumerState<DialogueScreen> createState() => DialogueScreenState();
}