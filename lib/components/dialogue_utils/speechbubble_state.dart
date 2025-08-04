
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/components/player.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class SpeechBubbleState extends State<SpeechBubble> with TickerProviderStateMixin {

  //position reference

  late PixelAdventure game;
  late Vector2 _playerPosition;

  ///state variables
  //currently displayed text
  String _displayedText = '';

  //Timers
  Timer? _typingTimer;
  Timer? _dismissTimer;

  // Typing-related values current character index _displayedtext TODO: Check if typeranimatedtext plugin is better
  int _currentIndex = 0;
  bool _isTypingComplete = false;
  bool _isSpeechBubbleVisible = false;

  ///Animationcontrollers
  //controls scaling-in
  late AnimationController _scaleController;
  //controls fading-out
  late AnimationController _fadeController;
  //controls movement
  late AnimationController _positionController;

  //scale for entrance
  late Animation<Animation> _scaleAnimation;
  //scale for exit
  late Animation<Animation> _fadeAnimation;
  //position controller
  late Animation<Offset> _positionAnimation;


  @override
  void initState(){
    super.initState();

    }

  @override
  Widget build(BuildContext context) {
   //_playerPosition =  game.player.position;
    throw UnimplementedError();
  }


}