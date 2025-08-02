import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'dialogue_engine.dart';

class DialogueScreen extends StatefulWidget {

  final VoidCallback onDialogueFinished;
  
  const DialogueScreen({super.key, required PixelAdventure game, required this.onDialogueFinished});
  
  @override
  State<StatefulWidget> createState() => DialogueScreenState();
}