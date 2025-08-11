import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/components/level_components/checkpoint/checkpoint.dart';
import 'package:mpg_achievements_app/components/level_components/collectables.dart';
import 'package:mpg_achievements_app/components/level_components/enemy.dart';
import 'package:mpg_achievements_app/components/physics/movement_collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'level_components/saw.dart';

//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with
        HasGameReference<PixelAdventure>,
        KeyboardHandler,
        CollisionCallbacks,
        HasCollisions,
        BasicMovement,
        KeyboardControllableMovement,
        AnimationManager,
        HasMovementAnimations,
        JoystickControllableMovement {
  //bools
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;

  // variable to store the latest checkpoint (used for respawning)
  Checkpoint? lastCheckpoint;

  // HP variables, if we decide to include these (if not set both to 1)
  int startHP = 3;
  int lives = 3;
  bool gotHit = false;

  //starting position
  Vector2 startingPosition = Vector2.zero();

  //Player name
  String playerCharacter;

  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required this.playerCharacter, super.position});

  @override
  FutureOr<void> onLoad() {
    startingPosition = Vector2(position.x, position.y);
    return super.onLoad();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyR)) {
      _respawn(); //press r to reset player
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyX)) {
      print(
        hitbox.isColliding,
      ); //press x to print if the player is currently in a wall
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {
      debugNoClipMode = !debugNoClipMode;
      setDebugNoCipMode(debugNoClipMode);
    } //press C to toggle noClip mode. lets you fall / walk / fly through walls. better only use it whilst flying (ctrl key)
    if (keysPressed.contains(LogicalKeyboardKey.keyY)) {
      debugImmortalMode = !debugImmortalMode; //press Y to toggle immortality
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyK)) {
      print('joystick'); //press H to reset lives
    }

    return super.onKeyEvent(event, keysPressed);
  }

  //checking collisions with an inbuilt method that checks if player is colliding
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the player checks if the hitbox that it is colliding with is a Collectable or saw, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Collectable) {
      other.collidedWithPlayer();
      game.overlays.add('SpeechBubble');
    }

    if (other is Saw && !debugImmortalMode) _hit();
    if (other is Enemy && !debugImmortalMode) _hit();
    if (other is Collectable && other.interactiveTask) {
      game.showDialogue = true;
      game.overlays.add('DialogueScreen');
    }
    super.onCollision(intersectionPoints, other);
  }

  void _hit() async {
    if (gotHit) return;
    lives = lives - 1;
    if (lives <= 0) {
      _respawn();
      return;
    }
    gotHit = true;
    playAnimation('hit');
    await Future.delayed(Duration(milliseconds: 250));
    gotHit = false;
  }

  void _respawn() async {
    if (gotHit) return; //if the player is already being respawned, stop
    updateMovement = false;
    gotHit = true; //indicate, that the player is being respawned
    playAnimation("hit");
    velocity = Vector2.zero(); //reset velocity
    setGravityEnabled(false); //temporarily disable gravity for this player

    await Future.delayed(
      Duration(milliseconds: 250),
    ); //wait a quarter of a second for the animation to finish
    position -= Vector2.all(
      32,
    ); //center the player so that the animation displays correctly (its 96*96 and the player is 32*32)
    scale.x =
        1; //flip the player to the right side and a third of the size because the animation is triple of the size
    playAnimation("disappearing"); //display a disappear animation
    await Future.delayed(
      Duration(milliseconds: 320),
    ); //wait for the animation to finish
    // respawn position is the last checkpoints position

    if (lastCheckpoint != null) {
      position = lastCheckpoint!.position - Vector2(40, 32);
    } //position the player at the spawn point and also add the displacement of the animation
    scale = Vector2.all(0); //hide the player
    await Future.delayed(
      Duration(milliseconds: 800),
    ); //wait a bit for the camera to position and increase the annoyance of the player XD
    scale = Vector2.all(1); //show the player
    playAnimation("appearing"); //display an appear animation
    await Future.delayed(
      Duration(milliseconds: 300),
    ); //wait for the animation to finish

    updatePlayerstate(); //update the players feet to the ground
    gotHit = false; //indicate, that the respawn process is over
    position += Vector2.all(
      32,
    ); //reposition the player, because it had a bit of displacement because of the respawn animation
    setGravityEnabled(true); //re-enable gravity
    updateMovement = true;
    lives = startHP;
  }

  //Getters
  @override
  ShapeHitbox getHitbox() => hitbox;

  @override
  Vector2 getPosition() => position;

  @override
  Vector2 getScale() => scale;

  @override
  Vector2 getVelocity() => velocity;

  //setters
  @override
  void setIsOnGround(bool val) => isOnGround = val;

  @override
  void setPos(Vector2 newPos) => position = newPos;

  bool climbing = false;

  @override
  void setClimbing(bool val) => climbing = val;

  @override
  bool get isClimbing => climbing;

  @override
  bool get isTryingToGetDownLadder => isShifting;

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions(
      "appearing",
      "Main Characters/Appearing",
      textureSize: 96,
      loop: false,
    ),
    AnimationLoadOptions(
      "disappearing",
      "Main Characters/Disappearing",
      textureSize: 96,
      loop: false,
    ),
    AnimationLoadOptions(
      "hit",
      "$componentSpriteLocation/Hit",
      textureSize: 32,
      loop: false,
    ),

    ...movementAnimationDefaultOptions,
  ];

  @override
  String get componentSpriteLocation => "Main Characters/Ninja Frog";

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.entity;

  @override
  bool get isInHitFrames => gotHit;
}
