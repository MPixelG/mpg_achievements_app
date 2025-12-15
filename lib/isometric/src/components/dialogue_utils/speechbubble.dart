import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/isometric/src/components/dialogue_utils/speechbubble_engine.dart';
import 'package:mpg_achievements_app/isometric/src/core/iso_component.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class SpeechBubble extends ConsumerStatefulWidget {
  //text to display and position
  final bool isRapidText;
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
    this.isRapidText = false,
  });

  @override
  ConsumerState<SpeechBubble> createState() => SpeechBubbleState();
}