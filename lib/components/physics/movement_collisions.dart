import 'dart:async';
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/entity/gameCharacter.dart';
import 'package:mpg_achievements_app/components/util/utils.dart' as util;
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/physics/isometric_hitbox.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'collision_block.dart';
import '../level/level.dart';


enum ViewSide { topDown, side, isometric }

/// Mixin for adding collision detection behavior to a component.
/// Requires implementing methods to provide hitbox, position, velocity, etc
mixin HasCollisions on GameCharacter, CollisionCallbacks, HasGameReference<PixelAdventure>, BasicMovement {
  ShapeHitbox getHitbox();

  Vector2 getScale();

  Vector2 getVelocity();

  Vector2 getPosition();

  void setClimbing(bool val);

  void setDebugNoClipMode(bool val) => _debugNoClipMode = val;

  bool get isTryingToGetDownLadder;

  bool _debugNoClipMode = false;

  late ShapeHitbox hitbox;
  @override
  FutureOr<void> onLoad() {
    if(viewSide == ViewSide.isometric) {
      hitbox = IsometricHitbox(
          Vector2.all(1),
          game.level,
          Vector2.zero()
      );
      hitbox.position = Vector2(0, 16);
    } else {
      hitbox = RectangleHitbox(
        position: Vector2(4, 6),
        size: Vector2(24, 26),
      );
    }

    add(hitbox);
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if(viewSide != ViewSide.side && !_debugNoClipMode) {
      gridPos = lastSafePosition;
      velocity = Vector2.zero();
      return;
    }



    if (other is CollisionBlock && !_debugNoClipMode) {
      checkCollision(other);
    }
    super.onCollision(intersectionPoints, other);
  }

  // Called when the collision with another object ends
  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if(viewSide == ViewSide.side){

      Future.delayed((Duration(milliseconds: 100)), () { //reset isOnGround after a short delay so that its a bit more forgiving when jumping from edges (lol)
        if (!activeCollisions.any((element) => element is CollisionBlock)) {
          isOnGround = false;
        }
      });

      if (other is CollisionBlock && other.climbable) {
        setClimbing(false);
      }
    }

  }

  //main collision physics
  void checkCollision(PositionComponent other) {
    if (other is! CollisionBlock) {
      return; //physics only work on the collision blocks (including the platforms)
    }

    ShapeHitbox hitbox = getHitbox();
    Vector2 scale = getScale();
    Vector2 velocity = getVelocity();

    Vector2 position = getPosition();

    Vector2 posDiff =
        hitbox.absolutePosition -
            other
                .absolutePosition; //the difference of the position of the player hitbox and the obstacle hitbox. this allows you to see how much they are overlapping on the different axis.

    //if the player faces in the other direction, we want to measure the distances from the other side of the hitbox. so we just add the width of it to the value.
    if (scale.x < 0) {
      posDiff.x -= hitbox.width;
    }

    //get all the distances it would take to transport the player to this side of the platform
    final double distanceUp = posDiff.y + hitbox.height;
    final double distanceLeft = posDiff.x + hitbox.width;
    final double distanceRight = other.width - posDiff.x;
    final double distanceDown = other.height - posDiff.y;

    final double smallestDistance = min(
      min(distanceUp, distanceDown),
      min(distanceRight, distanceLeft),
    ); //get the smallest distance

    // Resolve the collision in the direction of smallest overlap
    if (smallestDistance == distanceUp &&
        velocity.y > 0 &&
        !(!other.hasCollisionDown && distanceUp > 8) &&
        other.hasCollisionUp &&
        !(other.isLadder && isTryingToGetDownLadder)) {
      position.y -= distanceUp;
      isOnGround = true;
      velocity.y = 0;
    } //make sure you're falling (for platforms), then update the position, set the player on the ground and reset the velocity. if the block is a platform, then only move the player if the distance isn't too high, otherwise if half of the player falls through  a platform, he gets teleported up
    if (smallestDistance == distanceDown && other.hasCollisionDown) {
      position.y += distanceDown;
      velocity.y = 0;
    } //make sure the block isn't a platform, so that you can go through it from the bottom
    if (smallestDistance == distanceLeft && other.hasHorizontalCollision) {
      position.x -= distanceLeft;
      velocity.x = 0;
    } //make sure the block isn't a platform, so that you can go through it horizontally
    if (smallestDistance == distanceRight && other.hasHorizontalCollision) {
      position.x += distanceRight;
      velocity.x = 0;
    }
    if (other.climbable && distanceUp > 5) setClimbing(true);
  }

  Vector2 lastSafePosition = Vector2.zero();
  @override
  void update(double dt) {
    if (viewSide != ViewSide.isometric || _debugNoClipMode) return super.update(dt);

    if(!activeCollisions.isNotEmpty && !activeCollisions.any((element) => element is CollisionBlock)){
      lastSafePosition = gridPos;
    }
    super.update(dt);
  }


}



mixin BasicMovement on GameCharacter, HasGameReference<PixelAdventure> {
  //constants for configuring basic movement
  final double _gravity = 20;
  final double _jumpForce = 12;
  final double _terminalVelocity = 150;
  final double _friction = 0.75;

  double moveSpeed = 3; // Speed multiplier

  double horizontalMovement = 0; // Directional input (left/right)
  double verticalMovement = 0; // Directional input (up/down)
  Vector2 velocity = Vector2.zero();

  //velocity along z-Axis
  double zVelocity = 0.0;
  //character's height off the ground plane
  double zPosition = 0.0;

  bool debugFlyMode = false;
  bool hasJumped = false;
  bool isOnGround = false;
  bool gravityEnabled = true;
  bool isShifting = false;
  bool updateMovement = true;

  late ViewSide viewSide;



 @override
  void update(double dt) {
    if (updateMovement) {
      _updateMovement(dt);
    }
  }

  void setMovementType(ViewSide newType) => viewSide = newType;

  void setGravityEnabled(bool val) => gravityEnabled = val;

  bool get isClimbing;

  // Updates movement logic based on input and physics
  void _updateMovement(double dt) {
    if (hasJumped) {
      if (isOnGround) {
        viewSide == ViewSide.isometric ? isometricJump() : jump();
      } else {
        hasJumped = false;
      }
    }
    // Horizontal movement and friction


    switch (viewSide) {
      case ViewSide.isometric:
        _performIsometricMovement(dt);
        break;

      case ViewSide.side:
        velocity.x += horizontalMovement * moveSpeed;
        velocity.x *=_friction * (dt + 1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
        if (gravityEnabled) {
          _performGravity(dt);
        } else {
          print('gravity not enabled');
        }
      //maybe not necessary if we don't have topdown at all
      case ViewSide.topDown:
        velocity.x += horizontalMovement * moveSpeed;
        velocity.y += verticalMovement * moveSpeed;
        velocity *= _friction * (dt + 1);
        break;
    }


    // Apply final velocity to position



    gridPos += velocity * dt;
  }

  // Applies gravity and falling mechanics
  void _performGravity(double dt) {
    if (!debugFlyMode && !isClimbing) {
      if (isClimbing) {
        velocity.y += _gravity * dt * 0.02; // Fall down
      } else {
        velocity.y += _gravity * dt;
      }
    } else {
      velocity.y += verticalMovement * moveSpeed * (dt * 1000);
      velocity.y *= pow(0.01, dt); // Simulated drag
    }
    //limit fallspeed to terminalVelocity
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
  }

  // For top-down movement (WASD) now handled in switch case
  /*void _performVerticalMovement(double dt) {
    velocity.y += verticalMovement * moveSpeed * (dt + 1);
    velocity.y *= _friction * (dt + 1);
  }*/

  void jump() {
    velocity.y = -_jumpForce;
    //otherwise the player can even jump even if he is in the air
    isOnGround = false;
    hasJumped = false;
  }

  //isometric movement logic
  void _performIsometricMovement(double dt) {
    velocity.x += horizontalMovement * moveSpeed;
    velocity.x *= _friction * (dt + 1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction

    velocity.y += verticalMovement * moveSpeed;
    velocity.y *= _friction * (dt + 1); //slowly decrease the velocity every frame so that the player stops after a time. decrease the value to increase the friction
  }


  void _performIsometricGravity(double dt) {
    // Only apply gravity if not on the ground
    if (!isOnGround) {
      zVelocity += _gravity * dt;
    }

    // Apply Z velocity to Z position
    zPosition += zVelocity * dt;

    // A simple ground check
    if (zPosition >= 0) {
      zPosition = 0;
      zVelocity = 0;
      isOnGround = true;
    }
  }

  //needs more work just basic
  void isometricJump() {
    if (isOnGround) {
      zVelocity = -_jumpForce;
      isOnGround = false;
      hasJumped = false;
    }
  }
}

mixin KeyboardControllableMovement
    on PositionComponent, BasicMovement, KeyboardHandler {
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

    //ternary statement if left key pressed then add -1 to horizontal movement if not add 0 = not moving
    if (isLeftKeyPressed) horizontalMovement--;
    if (isRightKeyPressed) horizontalMovement++;

    if (viewSide == ViewSide.isometric || viewSide == ViewSide.side) {
      if (keysPressed.contains(LogicalKeyboardKey.controlLeft)) {
        debugFlyMode = !debugFlyMode; // press left ctrl to toggle fly mode
      }
      //if the key is pressed than the player jumps in _updatePlayerMovement
      if (keysPressed.contains(LogicalKeyboardKey.space)) {
        if (debugFlyMode || isClimbing) {
          //when in debug mode move the player upwards
          if (isClimbing) {
            verticalMovement = -0.06;
          } else {
            verticalMovement = -1;
          }
        } else {
          hasJumped = true; //else jump
        }
      }

      if (keysPressed.contains(LogicalKeyboardKey.shiftLeft)) {
        //when in fly mode and shift is pressed, the player gets moved down
        if (isClimbing) {
          verticalMovement = 0.06;
        } else if (debugFlyMode)
          verticalMovement = 1;

        isShifting = true;
      } else {
        isShifting = false;
      }
    }
    if (viewSide == ViewSide.topDown || viewSide == ViewSide.isometric) {
      final isUpKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyW) ||
          keysPressed.contains(LogicalKeyboardKey.arrowUp);
      final isDownKeyPressed =
          keysPressed.contains(LogicalKeyboardKey.keyS) ||
          keysPressed.contains(LogicalKeyboardKey.arrowDown);

      if (isUpKeyPressed) verticalMovement--;
      if (isDownKeyPressed) verticalMovement++;
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyT)) {
      position = mouseCoords; //press T to teleport the player to the mouse
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyB)) {
      debugMode = !debugMode;
      (parent as Level).setDebugMode(debugMode);
    } //press Y to toggle debug mode (visibility of hitboxes and more)
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
          effect..onComplete = () {
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
        } else if (debugFlyMode)
        {  verticalMovement = 1;}
        else if (viewSide == ViewSide.isometric){
          verticalMovement = 1;
        }
        break;

      default:
        //No movement
        horizontalMovement = 0;
        if(viewSide == ViewSide.isometric){
        verticalMovement = 0;}

    }
  }
}