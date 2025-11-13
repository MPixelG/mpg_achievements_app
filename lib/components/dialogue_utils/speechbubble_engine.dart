import 'dart:async' as async;
import 'dart:async';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

class SpeechBubbleState extends ConsumerState<SpeechBubble>
    with TickerProviderStateMixin {
  //Position reference
  late Vector2 _bubblePosition;
  late double _componentHeight;
  late double _componentWidth;

  //offset from character(i.e. y/x position from head
  static const double _bubbleOffset = 40;

  //currently displayed text
  String _displayedText = '';
  //text to display
  int _currentIndex = 0;
  bool _isTypingComplete = false;
  bool _isSpeechBubbleVisible = false;

  //Timers
  async.Timer? _typingTimer;
  async.Timer? _dismissTimer;

  //Configuration of Widget and Animations
  //Duration between character appearing and text displaying
  late final Duration typingSpeed = const Duration(milliseconds: 20);
  late final Duration showDuration = const Duration(seconds: 15);
  late final Duration dismissDuration = const Duration(seconds: 30);
  bool _autoDismiss =
      true; // Automatically dismiss the speech bubble after a certain duration
  bool autoStart =
      true; // Automatically start the speech bubble animation when the widget is built

  //styling
  late final Color textColor = Colors.black;
  late final double fontSize = 12;
  late final EdgeInsets padding = const EdgeInsets.all(8.0);
  late final BorderRadius borderRadius = BorderRadius.circular(8.0);
  late final bool showTail = true;
  // 1. Define constants and styles for easy configuration.
  static const int maxLinesBeforeScroll = 3;
  static const TextStyle textStyle = TextStyle(
    color: Colors.black,
    fontSize: 14,
    fontFamily: 'gameFont',
    height: 1.2, // Standard line height for accurate calculation
  );

  //Calculate the maximum height for the text area.
  // This is more robust than hardcoding pixel values.
  final double singleLineHeight = textStyle.fontSize! * textStyle.height!;
  late final double maxScrollableHeight =
      singleLineHeight * maxLinesBeforeScroll;

  //styling for the tail of the speech bubble
  // Define the tail's dimensions. You can adjust these.
  static const double tailWidth = 20.0;
  static const double tailHeight = 15.0;
  final Color borderColor = Colors.black; // Color of the tail border
  final double borderWidth = 1.0; // Width of the tail border

  //controls scaling-in
  late AnimationController _scaleController;

  //controls fading-out
  late AnimationController _fadeController;

  ///Animations
  //scale for entrance
  late Animation<double> _scaleAnimation;

  //scale for exit
  late Animation<double> _fadeAnimation;

  //choices?
  bool get _isChoiceBubble => widget.choices != null;

  @override
  void initState() {
    super.initState();

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
      curve: Curves.elasticOut,
    );

    // Initialize the fade animation for exit
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.linear));

    //Use WidgetsBinding to ensure the widget is fully built before starting the animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start the speech bubble animation
      _initializeSpeechBubble();
    });
  }

  //we can detect when the text or choices have changed and trigger our restartSpeechBubble method, which now correctly !!!cancels old timers and re-initializes the state from scratch.
  @override
  void didUpdateWidget(SpeechBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent widget rebuilt with different content for us...
    if (widget.text != oldWidget.text || widget.choices != oldWidget.choices) {
      //we must do a full restart to ensure the state is clean.
      Future.microtask(() => restartSpeechBubble());
    }
  }

  Future<void> _initializeSpeechBubble() async {
    if (!mounted) return;
    // Choice bubbles should not auto-dismiss
    _autoDismiss = !_isChoiceBubble;
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

    await _scaleController.forward();

    if (!_isSpeechBubbleVisible || !mounted) return;
    if (_isChoiceBubble || widget.text.isEmpty) {
      _onTypingComplete();
    } else {
      // After the scale animation completes, start the typing text
      _startTypingText();
    }
  }

  @override
  void dispose() {
    // Dispose of the controllers to free up resources
    _scaleController.dispose();
    _fadeController.dispose();
    _typingTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startTypingText() {
    _typingTimer?.cancel();
    _isTypingComplete = false;

    if (widget.text.isEmpty) {
      _onTypingComplete();
      return;
    }

    _typingTimer = async.Timer.periodic(typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Convert the full text to a list of runes (complete characters)
      final runes = widget.text.runes.toList();
      //check if there is still text to display
      if (_currentIndex < runes.length) {
        setState(() {
          // Build the displayed text from the list of runes
          // This is safe and will never split a character.
          final currentRunes = runes.sublist(0, _currentIndex);
          _displayedText = String.fromCharCodes(currentRunes);
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
    if (!mounted)
      return; // Check if the widget is still mounted before updating state

    setState(() {
      _isTypingComplete = true;
      // For choice bubbles, ensure the full text is displayed immediately.
      // Ensure full text is displayed for choice bubbles
      if (_isChoiceBubble) {
        _displayedText = widget.text;
      }
    });

    widget.onComplete
        ?.call(); // Call the callback if provided to notify that typing is complete

    if (_autoDismiss) {
      _dismissTimer?.cancel();
      // If autoDismiss is true, start the dismiss timer
      _dismissTimer = async.Timer(dismissDuration, () {
        _dismissSpeechBubble();
      });
    }
  }

  Future<void> _dismissSpeechBubble() async {
    if (!mounted) return;
    // Start the fade animation
    _fadeController.forward().then((_) {
      if (mounted) {
        // After the fade animation completes, set visibility to false
        setState(() {
          _isSpeechBubbleVisible = false;
          _displayedText = ''; // Clear the displayed text
          _currentIndex = 0; // Reset the current index for next use
        });
        widget.onDismiss?.call();
      }
    });
  }

  void restartSpeechBubble() {
    // Cancel any existing timers
    _typingTimer?.cancel();
    _dismissTimer?.cancel();

    // Reset the state of the speech bubble
    setState(() {
      _displayedText = '';
      _currentIndex = 0;
      _isTypingComplete = false;
      _isSpeechBubbleVisible = false;
    });

    // Reset the animation controllers
    _scaleController.reset();
    _fadeController.reset();

    // Restart the animation
    _initializeSpeechBubble();
  }

  // UI Building
  @override
  Widget build(BuildContext context) {
    try {
      if (!_isSpeechBubbleVisible) {
        return const SizedBox.shrink(); // Render nothing if not visible
      }

      // Initialize the player position and height
      _componentHeight = widget.component.height;
      _componentWidth = widget.component.width;
      // Adjust the position based on the camera's local to global conversion
      _bubblePosition = widget.game.cam.localToGlobal(
        toWorldPos(widget.component.position),
      );

      return AnimatedPositioned(
        // The position is now directly derived from the character's state vector
        left: _bubblePosition.x,
        // Center the bubble horizontally
        top: _bubblePosition.y - _componentHeight - _bubbleOffset,
        // Position above the character
        // Position above the character
        // Use the bubbleOffset to adjust the position if needed
        duration: const Duration(milliseconds: 100),
        // Animation duration for position change
        child: FadeTransition(
          //as the speech bubble fades out, it will also scale down
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              clipBehavior: Clip.none,
              // Allow the tail to extend outside the bubble
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(128),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxScrollableHeight,
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _displayedText,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontFamily: 'gameFont',
                            ),
                          ),
                        ),
                      ),
                      if (_isChoiceBubble) ...[
                        const SizedBox(height: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widget.choices!.options.map((option) {
                            final optionIndex = widget.choices!.options.indexOf(
                              option,
                            );
                            // Padding for vertical spacing between buttons
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                              ),
                              child: ElevatedButton(
                                onPressed: option.isAvailable
                                    ? () => widget.onChoiceSelected?.call(
                                        optionIndex,
                                      )
                                    : null,
                                child: Text(
                                  option.text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontFamily: 'gameFont',
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                Positioned(
                  left: 15,
                  bottom: -tailHeight,
                  child: CustomPaint(
                    // CustomPaint is used to draw the tail of the speech bubble
                    size: const Size(tailWidth, tailHeight),
                    painter: SpeechBubbleTailPainter(
                      bubbleColor: Colors.white,
                      borderColor: borderColor,
                      borderWidth: borderWidth,
                    ), // Color of the tail
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      // <-- ADD THIS
      print("!!!!!!!! UNHANDLED ERROR IN SPEECHBUBBLE BUILD !!!!!!!");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      return const SizedBox.shrink(); // Return an empty widget on error
    }
  }
}

//Tail Widget for Speech Bubble
// A custom painter to draw a triangular tail for the speech bubble.
class SpeechBubbleTailPainter extends CustomPainter {
  final Color bubbleColor;
  final Color borderColor;
  final double borderWidth;

  SpeechBubbleTailPainter({
    required this.borderColor,
    required this.borderWidth,
    required this.bubbleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a Paint object to define the color and style of the tail.
    final fillPaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle
          .stroke // Set the border color and style
      ..strokeWidth = borderWidth; // Set the border width
    // Create a Path object to define the shape of the triangle.

    final path = Path();
    path.moveTo(0, 0); // Start at the top-left of the painter's area
    path.lineTo(
      size.width / 2,
      size.height,
    ); // Draw a line to the bottom-center point
    path.lineTo(size.width, 0); // Draw a line to the top-right
    path.close(); // Close the path to form a solid triangle

    // Draw the path on the canvas.
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint); // Draw the border of the tail
  }

  @override
  // This method is called to determine if the painter should repaint.
  bool shouldRepaint(covariant SpeechBubbleTailPainter oldDelegate) {
    // The painter should only repaint if the color changes.
    return oldDelegate.bubbleColor != bubbleColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
