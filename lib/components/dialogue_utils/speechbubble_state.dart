
import 'dart:async'as async;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

class SpeechBubbleState extends State<SpeechBubble> with TickerProviderStateMixin {

  ///Position reference

  late PixelAdventure game;
  late Vector2 _playerPosition;
  late double xPosition;
  late double yPosition;
  //Current position of the character
  late  Offset targetPosition;
  //offset from character(i.e. y/x position from head
  late  Offset bubbleOffset;

  ///state variables
  //currently displayed text
  String _displayedText = '';

  //Timers
  late async.Timer _typingTimer;
  late async.Timer _dismissTimer;
  //Typing-related values current character index _displayedtext TODO: Check if typeranimatedtext plugin is better
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

    // Initialize the game reference
    _playerPosition = game.player.position;

    xPosition = _playerPosition.x;
    yPosition = _playerPosition.y;
    targetPosition = Offset(xPosition, yPosition);
    bubbleOffset = Offset(0, -50); // Adjust this offset as needed relative to

    // Initialize the scale controller for entrance animation
    _scaleController = AnimationController(
      //Provided by the TickerProviderStateMixin
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize the fade controller for exit animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize the position controller for movement animation
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize the scale animation for entrance
    //A Tween is used to define the range of the animation, smoothly transitioning from begin value to end value
    _scaleAnimation = Tween<double>(
      begin: 0.0,//Start invisible
      end: 1.0,  // End fully visible
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut)) as Animation<Animation>;

    // Initialize the fade animation for exit
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _fadeController,
        curve: Curves.elasticOut)) as Animation<Animation>;

    // Initialize the position animation for movement
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(bubbleOffset.dx, bubbleOffset.dy),
    ).animate(CurvedAnimation(parent: _positionController, curve: Curves.easeInOut));

    //start the animation if autostart is true
    if(widget.autoStart) {
      _startAnimationSpeechBubble();

     }

    }


    @override
    void dispose() {
      super.dispose();
    // Dispose of the controllers to free up resources
    _scaleController.dispose();
    _fadeController.dispose();
    _positionController.dispose();
    _typingTimer.cancel();
    _dismissTimer.cancel();

    }

    void _startAnimationSpeechBubble() {
      //Visibility true
      setState(() {
        _isSpeechBubbleVisible = true;
      });
      //Start the scale animation forward start the animation, then happens after thje animation completes
      _scaleController.forward().then((_) {
        // Start typing the text after the scale animation completes
        _startTypingText();

    });

          }

  @override
  Widget build(BuildContext context) {
   throw UnimplementedError();
  }


  void _startTypingText() {
  if(_displayedText.isEmpty) {
    _isTypingComplete = true;
    return; // If there's no text to type, do nothing
  }

    _typingTimer = async.Timer.periodic(widget.typingSpeed, (timer){
        //check if there is still text to display
      if(_currentIndex < widget.text.length) {
        setState(() {
          // Append the next character to the displayed text
          _displayedText = widget.text.substring(0, _currentIndex + 1);

          _currentIndex++;
        });
      } else {
        // Stop the typing timer when the text is fully displayed
        timer.cancel();
        // Start the dismiss timer after typing is complete
        _onTypingComplete();

      }

    });
  }


  void _onTypingComplete() {
    setState(() {
      _isTypingComplete = true;
    });

    widget.onComplete?.call(); // Call the callback if provided to notify that typing is complete

    // If autoDismiss is false, the speech bubble will remain visible until manually dismissed
    if(!widget.autoDismiss) {
      // If autoDismiss is false, the speech bubble will remain visible until manually dismissed
      // You can add any additional logic here if needed
      print("Speech bubble typing complete, waiting for manual dismissal.");
    }

    if(widget.autoDismiss) {// If autoDismiss is true, start the dismiss timer
     _dismissTimer = async.Timer(widget.dismissDuration, () {
      _dismissSpeechBubble();});
    }
    }


  void _dismissSpeechBubble() {
    // Start the fade animation
    _fadeController.forward().then((_) {
      // After the fade animation completes, set visibility to false
      setState(() {
        _isSpeechBubbleVisible = false;
        _displayedText = ''; // Clear the displayed text
        _currentIndex = 0; // Reset the current index for next use
        widget.onDismiss?.call();
      });
          });
        }


  void restartSpeechBubble() {
    // Reset the state of the speech bubble
    setState(() {
      _displayedText = '';
      _currentIndex = 0;
      _isTypingComplete = false;
      _isSpeechBubbleVisible = false;
    });

    // Cancel any existing timers
    _typingTimer.cancel();
    _dismissTimer.cancel();

    // Reset the animation controllers
    _scaleController.reset();
    _fadeController.reset();
    _positionController.reset();

    // Restart the animation
    _startAnimationSpeechBubble();

  }

}


