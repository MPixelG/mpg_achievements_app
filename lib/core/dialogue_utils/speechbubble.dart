import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_containing_game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/speechbubble_engine.dart';

class SpeechBubble extends ConsumerStatefulWidget {
  //text to display and position
  final bool isRapidText;
  final DialogueCharacter component;//more generic
  final String text;
  final DialogueContainingGame game;
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