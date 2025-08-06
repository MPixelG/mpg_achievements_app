import 'dart:async' as async;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';


class SpeechBubbleState extends State<SpeechBubble>
    with TickerProviderStateMixin {
  ///Position reference

  late Vector2 _playerPosition;

  //Current position of the character
  late Offset _targetPosition;

  //offset from character(i.e. y/x position from head
  late Offset _bubbleOffset;
  late Offset _currentPosition;

  ///State variables
  //currently displayed text
  String _displayedText = '';
  //text to display
  late String text = 'Hello, this is a speech bubble example!';
  int _currentIndex = 0;
  bool _isTypingComplete = false;
  bool _isSpeechBubbleVisible = false;
  late final String characterName = widget.characterName;

  //Timers
  late async.Timer? _typingTimer;
  late async.Timer? _dismissTimer;


  //Configuation of Widget and Animations
  //Duration between character appearing and text displaying
  late final Duration typingSpeed = const Duration(milliseconds: 100);
  late final Duration showDuration = const Duration(seconds: 5);
  late final Duration dismissDuration = const Duration(seconds: 3);
  late final bool autoDismiss = true;
  late final bool autoStart = false;


  //styling
  late final Color textColor = Colors.black;
  late final double fontSize = 12;
  late final EdgeInsets padding = const EdgeInsets.all(8.0);
  late final BorderRadius borderRadius = BorderRadius.circular(8.0);
  late final bool showTail = true;



  ///Animationcontrollers
  //controls scaling-in
  late AnimationController _scaleController;

  //controls fading-out
  late AnimationController _fadeController;

  ///Animations
  //scale for entrance
  late Animation<double> _scaleAnimation;

  //scale for exit
  late Animation<double> _fadeAnimation;




  @override
  void initState() {
    super.initState();

    // Initialize the game reference
    _playerPosition = widget.game.player.position;

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


    //A Tween is used to define the range of the animation, smoothly transitioning from begin value to end value
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,);

    // Initialize the fade animation for exit
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _fadeController,
          curve: Curves.linear),
    );

       //start the animation if autostart is true
    if (autoStart) {
      //Use WidgetsBinding to ensure the widget is fully built before starting the animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Start the speech bubble animation
        _startAnimationSpeechBubble();
      });

    }
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose of the controllers to free up resources
    _scaleController.dispose();
    _fadeController.dispose();
    _typingTimer?.cancel();
    _dismissTimer?.cancel();
  }



  /// Updates the target position of the speech bubble based on the player's position

  @override
  void didUpdateWidget(SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.game.player.position != _playerPosition) {
      // If the player's position has changed, update the target position
      setState((){_playerPosition = widget.game.player.position;});
    }
  }



// UI Building
  /// Builds the speech bubble widget
  @override
  Widget build(BuildContext context) {
    if (!_isSpeechBubbleVisible) {
      return const SizedBox.shrink(); // Render nothing if not visible
    }

    return AnimatedPositioned(
      // The position is now directly derived from the character's state vector
      left: _playerPosition.x,
      top: _playerPosition.y - 60, // Bubble offset (adjust as needed)
      duration: const Duration(milliseconds: 300),
      child: FadeTransition(
        //as the speech bubble fades out, it will also scale down
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(128),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              _displayedText,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

//Animation and Typing Logic

  void _startAnimationSpeechBubble() {
    //Visibility true
    setState(() {
      _isSpeechBubbleVisible = true;
      _displayedText = ''; // Clear the displayed text
      _currentIndex = 0; // Reset the current index for typing
      _isTypingComplete = false; // Reset typing completion state

    });
    //fade animation controller reset because it was used for exit animation of the speech bubble
    _fadeController.reset();
    //scaleController reset because it was used for entrance animation of the speech bubble
    _scaleController.reset();

    _scaleController.forward().then((_) {
      if(_isSpeechBubbleVisible) {
        // After the scale animation completes, start the typing text
        _startTypingText();
        // After the scale animation completes, start typing the text
      _startTypingText();}
    });
  }


  void _startTypingText() {
    if (text.isEmpty) {
      _onTypingComplete();
      return;
      }

      _typingTimer = async.Timer.periodic(typingSpeed, (timer) {
      //check if there is still text to display
      if (_currentIndex < text.length) {
        setState(() {
          // Append the next character to the displayed text
          _displayedText = text.substring(0, _currentIndex + 1);

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

    widget.onComplete!(); // Call the callback if provided to notify that typing is complete

    // If autoDismiss is false, the speech bubble will remain visible until manually dismissed
    if (!autoDismiss) {
      // If autoDismiss is false, the speech bubble will remain visible until manually dismissed
      // You can add any additional logic here if needed
      print("Speech bubble typing complete, waiting for manual dismissal.");
    }

    if (autoDismiss) {
      // If autoDismiss is true, start the dismiss timer
      _dismissTimer = async.Timer(dismissDuration, () {
        _dismissSpeechBubble();
      });
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
        widget.onDismiss!();
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
    _typingTimer?.cancel();
    _dismissTimer?.cancel();

    // Reset the animation controllers
    _scaleController.reset();
    _fadeController.reset();

    // Restart the animation
    _startAnimationSpeechBubble();
  }
}
