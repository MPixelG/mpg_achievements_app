import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble_state.dart';
import '../../mpg_pixel_adventure.dart';

class SpeechBubble extends ConsumerStatefulWidget {
  //text to display and position
  final String characterName;
  final Offset targetPosition;
  final Offset currentPosition; //todo convert to 3d coords
  final PixelAdventure game;

  //callback
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;

  const SpeechBubble({
    super.key,
    required this.characterName,
    this.onComplete,
    this.onDismiss,
    required this.targetPosition,
    required this.game,
    required this.currentPosition,
  });

  @override
  ConsumerState<SpeechBubble> createState() => SpeechBubbleState();
}
