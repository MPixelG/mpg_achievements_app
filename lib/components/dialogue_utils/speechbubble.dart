import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble_engine.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import '../../mpg_pixel_adventure.dart';

class SpeechBubble extends ConsumerStatefulWidget {
  //text to display and position
  final Player player;
  final Offset targetPosition;
  final Offset currentPosition; //todo convert to 3d coords
  final PixelAdventure game;
  final String yarnFilePath;
  final Map<String, Function> commands;

  //callback
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;

  const SpeechBubble({
    super.key,
    required this.player,
    this.onComplete,
    this.onDismiss,
    required this.targetPosition,
    required this.game,
    required this.currentPosition,
    required this.yarnFilePath,
    required this.commands,
  });

  @override
  ConsumerState<SpeechBubble> createState() => SpeechBubbleState();
}
