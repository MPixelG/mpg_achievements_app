import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble_engine.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import '../../mpg_pixel_adventure.dart';

class SpeechBubble extends ConsumerStatefulWidget {
  //text to display and position
  final IsoPositionComponent component; //more generic
  final String text;
  final PixelAdventure game;
  final DialogueChoice? choices;

  //callback
  final VoidCallback? onComplete;
  final VoidCallback? onDismiss;
  final ValueChanged<int>? onChoiceSelected;

  const SpeechBubble({
    super.key,
    required this.component,
    required this.text,
    this.choices,
    this.onComplete,
    this.onDismiss,
    required this.game,
    this.onChoiceSelected,
  });

  @override
  ConsumerState<SpeechBubble> createState() => SpeechBubbleState();
}
