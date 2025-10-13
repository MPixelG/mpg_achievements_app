import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'dialogue_engine.dart';

class DialogueScreen extends ConsumerStatefulWidget {
  final VoidCallback onDialogueFinished;
  final PixelAdventure game;

  const DialogueScreen({
    super.key,
    required this.onDialogueFinished,
    required this.game,
  });

  @override
  ConsumerState<DialogueScreen> createState() => DialogueScreenState();
}
