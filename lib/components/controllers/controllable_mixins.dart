import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/core/physics/collisions.dart';
import 'package:mpg_achievements_app/core/physics/isometric_movement.dart';
import 'package:mpg_achievements_app/core/physics/movement.dart';

import '../../core/level/game_world.dart';
import '../../mpg_pixel_adventure.dart';
import '../../util/utils.dart' as util;

mixin KeyboardControllableMovement
    on PositionComponent, BasicMovement, KeyboardHandler, IsometricMovement {
  bool _active = true;
  Vector2 mouseCoords = Vector2.zero();

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (!_active) return super.onKeyEvent(event, keysPressed);

    horizontalMovement = 0;
    verticalMovement = 0;

    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    if (isLeftKeyPressed) {
      //checking if isometric Movement is set to true or false
      if(!PixelAdventure.isometricMovement){
        horizontalMovement = horizontalMovement - 0.5;
        verticalMovement = verticalMovement + 0.5;
      }
      else{
        horizontalMovement--;
      }
    }
    if (isRightKeyPressed) {
      //checking if isometric Movement is set to true or false
      if(!PixelAdventure.isometricMovement){
        horizontalMovement = horizontalMovement + 0.5;
        verticalMovement = verticalMovement - 0.5;
      }
      else{
        horizontalMovement++;
      }
    }
    //ternary statement if left key pressed then add -1 to horizontal movement if not add 0 = not moving


    if (viewSide != ViewSide.isometric && viewSide != ViewSide.side) super.onKeyEvent(event, keysPressed);
    if (keysPressed.contains(LogicalKeyboardKey.controlLeft)) {
      debugFlyMode = !debugFlyMode; // press left ctrl to toggle fly mode
    }

    // If the space key is pressed, handle the jump/fly logic.
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      // First, check for special movement states that override a standard jump.
      if (debugFlyMode || isClimbing) {
        final upwardThrottle = isClimbing ? -0.6 : -1.0;

        if (viewSide == ViewSide.isometric) {
          print('isometric jump');
           zMovement = upwardThrottle;
        } else {
          verticalMovement = upwardThrottle;
        }
      } else {
        hasJumped = true;
        print('hasJumped:$hasJumped');
      }
    }

    if (keysPressed.contains(LogicalKeyboardKey.shiftLeft)) {
      //when in fly mode and shift is pressed, the player gets moved down
      if (isClimbing) {
        verticalMovement = 0.06;
      } else if (debugFlyMode) {
        verticalMovement = 1;
      }


      isShifting = true;
    } else {
      isShifting = false;
    }

    if (viewSide == ViewSide.isometric) {
      final isUpKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyW) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp);
      final isDownKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyS) ||
          keysPressed.contains(LogicalKeyboardKey.arrowDown);

      if (isUpKeyPressed) {
        //checking if isometric Movement is set to true or false
        if(!PixelAdventure.isometricMovement){
          verticalMovement = verticalMovement - 0.5;
          horizontalMovement = horizontalMovement - 0.5;
        }
        else{
          verticalMovement--;
        }
      }
      if (isDownKeyPressed) {
        //checking if isometric Movement is set to true or false
        if(!PixelAdventure.isometricMovement){
          verticalMovement = verticalMovement + 0.5;
          horizontalMovement = horizontalMovement + 0.5;
        }
        else{
          verticalMovement++;
        }
      }


    }
    if (viewSide == ViewSide.topDown) {
      throw UnimplementedError();
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyT)) {
      position = mouseCoords; //press T to teleport the player to the mouse
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {
      debugMode = !debugMode;
      (parent as GameWorld).setDebugMode(debugMode);
    } //press b to toggle debug mode (visibility of hitboxes and more)
    return super.onKeyEvent(event, keysPressed);
  }


  // Enable/disable player control
  bool setControllable(bool val) => _active = val;
}

mixin JoystickControllableMovement
    on PositionComponent, BasicMovement, HasGameReference<PixelAdventure> {
  bool active = util.shouldShowJoystick();

  // Joystick component for movement
  late JoystickComponent joystick;
  late ButtonComponent buttonComponent;

  @override
  void update(double dt) {
    if (!active) return super.update(dt);

    updateJoystick();
  }

  @override
  Future<void> onMount() async {
    super.onMount();

    ///Joystick Component
    //Making a Joystick if the platform is not web or desktop
    if (!active) return super.onMount();

    // paints for HUD elements
    final knobPaint = BasicPalette.black.withAlpha(100).paint();
    final backgroundPaint = Paint();
    final buttonPaint = Paint();
    backgroundPaint.color = Color.fromARGB(100, 151, 179, 174);
    buttonPaint.color = Color.fromARGB(100, 250, 243, 235);

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 10, paint: knobPaint),
      background: CircleComponent(radius: 40, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 25, bottom: 25),
    );

    buttonComponent = HudButtonComponent(
      button: CircleComponent(
        radius: 40,
        paint: knobPaint,
        anchor: Anchor.center,
      )..position = Vector2.all(40),
      buttonDown: CircleComponent(
        radius: 40,
        paint: buttonPaint,
        anchor: Anchor.center,
      )..position = Vector2.all(40),
      onPressed: () {
        // Jump Logic
        if (debugFlyMode || isClimbing) {
          if (isClimbing) {
            verticalMovement = -0.06;
          } else {
            verticalMovement = -1;
          }
        } else {
          hasJumped = true;
        }

        // Animation: Button "pop"
        final effect = ScaleEffect.to(
          Vector2.all(1.2), // a bit bigger than before
          EffectController(
            duration: 0.15,
            reverseDuration: 0.2,
            curve: Curves.easeOutBack, // easing
            reverseCurve: Curves.easeIn, // when returning
          ),
        );

        // resetting old effects to prevent stacking
        buttonComponent.button!.add(
          effect
            ..onComplete = () {
              // reset to original size
              buttonComponent.button!.scale = Vector2.all(1);
            },
        );
      },
      margin: const EdgeInsets.only(right: 25, bottom: 25),
    );

    // Add the joystick to the viewport
    game.cam.viewport.add(joystick);
    // Add the button component to the viewport
    game.cam.viewport.add(buttonComponent);
    // Then set position
  }

  void updateJoystick() {
    //define the horizontal and vertical movement based on the joystick direction
    final direction = joystick.direction;
    //define the horizontal and vertical movement based on the joystick intensity 0 to 1
    final intensity = joystick.intensity;

    switch (direction) {
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
      case JoystickDirection.left:
        horizontalMovement = -1 * intensity;
        break;
      case JoystickDirection.downRight:
      case JoystickDirection.upRight:
      case JoystickDirection.right:
        horizontalMovement = 1 * intensity;
        break;
      case JoystickDirection.up:
        if (debugFlyMode || isClimbing || viewSide == ViewSide.isometric) {
          //when in debug mode move the player upwards
          if (isClimbing) {
            verticalMovement = -0.06;
          } else {
            verticalMovement = -1;
          }
        } else {
          hasJumped = true; //else jump
        }

        break;
      case JoystickDirection.down:
        if (isClimbing) {
          verticalMovement = 0.06;
        } else if (debugFlyMode) {
          verticalMovement = 1;
        } else if (viewSide == ViewSide.isometric) {
          verticalMovement = 1;
        }
        break;

      default:
        //No movement
        horizontalMovement = 0;
        if (viewSide == ViewSide.isometric) {
          verticalMovement = 0;
        }
    }
  }
}
