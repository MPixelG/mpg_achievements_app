import 'dart:async' as async;
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jenny/jenny.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/speechbubble.dart';
import 'package:mpg_achievements_app/components/dialogue_utils/yarn_creator.dart';
import 'package:mpg_achievements_app/components/level_components/entity/player.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

class SpeechBubbleState extends ConsumerState<SpeechBubble>
    with TickerProviderStateMixin, DialogueView {

  //Position reference
  late Vector2 _playerPosition;
  late double _playerHeight;
  late double _playerWidth;

  //offset from character(i.e. y/x position from head
  late final double _bubbleOffset = 40;

  //currently displayed text
  String _displayedText = '';

  //text to display
  late String text = '';
  int _currentIndex = 0;
  bool _isTypingComplete = false;
  bool _isSpeechBubbleVisible = false;
  late final Player player = widget.game.gameWorld.player;

  //Timers
  late async.Timer? _typingTimer;
  late async.Timer? _dismissTimer;

  //Configuration of Widget and Animations
  //Duration between character appearing and text displaying
  late final Duration typingSpeed = const Duration(milliseconds: 150);
  late final Duration showDuration = const Duration(seconds: 5);
  late final Duration dismissDuration = const Duration(seconds: 10);
  late final bool autoDismiss =
      true; // Automatically dismiss the speech bubble after a certain duration
  late final bool autoStart =
      true; // Automatically start the speech bubble animation when the widget is built

  //styling
  late final Color textColor = Colors.black;
  late final double fontSize = 12;
  late final EdgeInsets padding = const EdgeInsets.all(8.0);
  late final BorderRadius borderRadius = BorderRadius.circular(8.0);
  late final bool showTail = true;
  late final double _buttonSpacing = 10;

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

  //variables for YarnEngine
  // The compiled Yarn project containing all nodes, lines, and commands.
  late final YarnProject _project;

  // The raw string content of the loaded .yarn file, used for the script viewer.
  late final String _rawYarnScript;

  // The Jenny engine instance that executes the dialogue logic.
  late DialogueRunner? _dialogueRunner;

  //A completer that pauses the [DialogueRunner].
  //
  // When `onLineStart` is called, a new completer is created. The runner
  // waits until `completer.complete()` is called, which happens when the user
  // clicks the "Next" button.

  Completer<bool>? _lineCompleter;

  // The current [DialogueLine] being displayed to the user.
  // If `null`, the dialogue UI is hidden.
  DialogueLine? _currentLine;
  DialogueChoice? _currentChoice;
  Completer<int>? _choiceCompleter;

  // A flag indicating whether the entire dialogue sequence has finished.
  // When `true`close conversation
  bool _isConversationFinished = false;

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
    //init typingtimer
    _typingTimer = async.Timer(const Duration(seconds: 5), _dismissSpeechBubble);
    //start the animation if autostart is true
    if (autoStart) {
      //Use WidgetsBinding to ensure the widget is fully built before starting the animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Start the speech bubble animation
        _initializeSpeechBubble();
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

  // UI Building
  /// Builds the speech bubble widget
  @override
  Widget build(BuildContext context) {
    if (!_isSpeechBubbleVisible) {
      return const SizedBox.shrink(); // Render nothing if not visible
    }

    // Initialize the player position and height
    _playerHeight = player.height;
    _playerWidth = player.width;
    // Adjust the position based on the camera's local to global conversion
    _playerPosition = widget.game.cam.localToGlobal(toWorldPos(player.position));


    return AnimatedPositioned(
      // The position is now directly derived from the character's state vector
      left: _playerPosition.x,
      // Center the bubble horizontally
      top: _playerPosition.y - _playerHeight - _bubbleOffset,
      // Position above the character
      // Position above the character
      // Use the bubbleOffset to adjust the position if needed
      duration: const Duration(milliseconds: 300),
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
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  _displayedText,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              if (_currentChoice != null)...[const SizedBox(height: 12.0),
              Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _currentChoice!.options.map((option){
                final optionIndex =
    _currentChoice!.options.indexOf(option);
                return ElevatedButton(
    onPressed: option.isAvailable ? () {
      _choiceCompleter?.complete(optionIndex);
      setState((){_currentChoice = null;});
    }
    :null,//disable button of option is not available
    child: Text(option.text),
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
  }

  //Animation and Typing Logic

  Future<void> _initializeSpeechBubble() async {

    // Helper class to load and parse the .yarn file.
    final yarnCreator = YarnCreator(
      widget.yarnFilePath, // Use the path from the widget
      commands: widget.commands,         // Use the commands from the widget
    );
    await yarnCreator.loadYarnFile();

    // Store the compiled project and the raw script text.
    _project = yarnCreator.project;
    _rawYarnScript = yarnCreator.script;

    // Create the DialogueRunner, providing it with the project and a
    // list of views. `[this]` means this class will handle UI events. properties passed into the widget are used for yarnCreation
    _dialogueRunner = DialogueRunner(
      yarnProject: _project,
      dialogueViews: [this],
    );

    // Start the dialogue from the node named 'Start'.
    _dialogueRunner?.startDialogue('Start');


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
      if (_isSpeechBubbleVisible) {
        // After the scale animation completes, start the typing text
        _startTypingText();
        // After the scale animation completes, start typing the text
        _startTypingText();
      }
    });
  }

  void _startTypingText() {
    _typingTimer?.cancel();
    _currentIndex = 0; //todo state management
    _displayedText ='';
    _isTypingComplete = false;

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
        // the text is fully displayed, stop the timer
        _typingTimer?.cancel();
        // Stop the typing timer when the text is fully displayed
        timer.cancel();
        // Start the dismiss timer after typing is complete
        _onTypingComplete();
      }
    });
  }

  @override
  Future<bool> onLineStart(DialogueLine line) async {
    // Create a new completer. The DialogueRunner will `await` this completer's future.
    final completer = Completer<bool>();

    // Update the state to display the new line and store the completer.
    // `setState` triggers a rebuild, showing the new text and the "Next" button.
    setState(() {
      _currentLine = line;
      text = line.text;
      _isConversationFinished =
      false; // A new line means the dialogue is not finished.
      _isSpeechBubbleVisible = true;
      _lineCompleter = completer;
    });

    _fadeController.reset();
    _scaleController.reset();
    await _scaleController.forward();

    _startTypingText();

    // Return the future. The runner is now paused.
    return completer.future;
  }

  @override
  Future<int?> onChoiceStart(DialogueChoice choice) {
   final choiceCompleter = Completer<int>();

    //stop autodismiss if choice in bubble
   _dismissTimer?.cancel();

   setState(() {
     _currentChoice = choice;
   });
    

    return choiceCompleter.future;
  }

  @override
  void onDialogueFinish() {
    // The DialogueRunner has finished all nodes in the conversation.

    setState(() {
      // Mark the dialogue as finished
      _isConversationFinished = true;
    });
    _dismissSpeechBubble();
  }

  // Shows a debug dialog displaying the raw content of the Yarn script.
  Future<void> _showScript() async {
    // Ensure the widget is still in the tree before showing a dialog.
    if (!mounted) return;

    //pause game
    widget.game.pauseEngine();

    await showDialog<void>(
      context: context,
      // The builder provides a `dialogContext` which is crucial for closing.
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Script Content'),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
            child: SingleChildScrollView(
              child: Text(
                _rawYarnScript,
                style: const TextStyle(fontFamily: 'gameFont'),
              ),
            ),
          ),
          SizedBox(height: _buttonSpacing),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              // Using `dialogContext` ensures we only pop the dialog itself,
              // not the entire dialogue screen or game view.
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      // Resume the game engine after the dialog is closed.
      widget.game.resumeEngine();
    }
  }


  void _onTypingComplete() {
    if (!mounted) {
      return; // Check if the widget is still mounted before updating state
    }
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

    if (autoDismiss && _currentChoice == null) {
      // If autoDismiss is true, start the dismiss timer
      _dismissTimer = async.Timer(dismissDuration, () {
        _dismissSpeechBubble();
      });
    }
  }

  void _dismissSpeechBubble() {
    // Start the fade animation
    _fadeController.forward().then((_) {
      if(mounted){
      // After the fade animation completes, set visibility to false
      setState(() {
        _isSpeechBubbleVisible = false;
        _displayedText = ''; // Clear the displayed text
        _currentIndex = 0; // Reset the current index for next use
        widget.onDismiss!();
      });}
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
    _initializeSpeechBubble();
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
