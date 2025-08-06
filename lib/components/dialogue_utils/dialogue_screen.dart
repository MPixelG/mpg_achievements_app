import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'dialogue_engine.dart';

class DialogueScreen extends StatefulWidget {
  final VoidCallback onDialogueFinished;
  final PixelAdventure game;

  const DialogueScreen({
    super.key,
    required this.onDialogueFinished, required this.game,
  });

  @override
  State<StatefulWidget> createState() => DialogueScreenState();
}
