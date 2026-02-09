import 'package:flame/game.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart' hide AnimationStyle, Image;
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_containing_game.dart';
import 'package:mpg_achievements_app/core/music/music_manager.dart';


//DragCallbacks are imported for touch controls
abstract class BaseGame extends FlameGame
    with
        DialogueContainingGame {

  @override
  Color backgroundColor() => const Color(0x00000000);
  final musicManager = MusicManager();

  Map<String, Widget Function(BuildContext, BaseGame)>? buildOverlayMap();
  
  @override
  bool showingDialogue = false;
}