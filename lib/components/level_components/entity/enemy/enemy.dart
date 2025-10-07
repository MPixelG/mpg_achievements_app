import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/level_components/entity/game_character.dart';
import 'package:mpg_achievements_app/components/level_components/saw.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';

import '../../../../core/level/isometric/isometric_world.dart';
import '../../../particles/particles.dart';
import '../../../physics/movement.dart';
import '../animation/animation_manager.dart';
import 'ai/goals/follow_player_goal.dart';
import 'ai/goals/goal_manager.dart';
import 'ai/goals/move_goal.dart';
import 'ai/goals/pathtracing_goal.dart';
import 'ai/goals/player_locating_goal.dart';

enum EnemyState {
  idle,
  running,
  jumping,
  falling,
  hit,
  appearing,
  disappearing,
}

class Enemy extends GameCharacter
    with
        KeyboardHandler,
        CollisionCallbacks,
        BasicMovement,
        HasCollisions,
        HasMovementAnimations {
  bool gotHit = false;
  bool isRespawning = false;

  //debug switches for special modes
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;

  //starting position
  Vector2 startingPosition = Vector2.zero();
  String enemyCharacter;

  //constructor super is reference to the SpriteanimationGroupComponent above, which contains position as attributes
  Enemy({
    required this.enemyCharacter,
    super.position,
    super.anchor = Anchor.center,
  });

  late GoalManager manager;
  @override
  FutureOr<void> onLoad() {
    startingPosition = Vector2(position.x, position.y);
    // The player inspects its environment (the level) and configures itself.
    if (game.gameWorld is IsometricWorld) {
      setMovementType(ViewSide.isometric);
    } else {
      setMovementType(ViewSide.side); // Default
    }
    manager = GoalManager();
    add(manager);

    PathtracingGoal goal = PlayerLocatingGoal(1);
    MoveGoal moveGoal = FollowPlayerGoal(0, game.gameWorld.player);

    manager.addGoal(goal);
    manager.addGoal(moveGoal);

    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the enemy checks if the hitbox that it is colliding with is a saw
    if (other is Saw && !debugImmortalMode) _respawn();
    super.onCollision(intersectionPoints, other);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    verticalMovement = 0;

    //movement keys
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyJ);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyL);

    //debug key bindings
    if (keysPressed.contains(LogicalKeyboardKey.keyF)) {
      position = game.gameWorld.player.position.clone();
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyG)) {
      debugFlyMode = !debugFlyMode;
    }

    //ternary statement if leftKey pressed then add -1 to horizontal movement if not add 0 = not moving
    if (isLeftKeyPressed) horizontalMovement = -1;
    if (isRightKeyPressed) horizontalMovement = 1;

    //if the key is pressed than the enemy jumps / flies
    if (keysPressed.contains(LogicalKeyboardKey.altRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyI)) {
      //right alt is more handy
      if (debugFlyMode) {
        verticalMovement = -1; //when in debug mode move the enemy upwards
      } else {
        hasJumped = true; //else jump
      }
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyK) && debugFlyMode) {
      //when in fly mode and shift is pressed, the enemy gets moved down
      verticalMovement = 1;
    }

    if (keysPressed.contains(LogicalKeyboardKey.comma)) {
      //press comma to get a surprise! (can also be used to generate lag XD )
      parent?.add(generateConfetti(position));
    }

    return super.onKeyEvent(event, keysPressed);
  }

  void _respawn() async {
    if (gotHit) return; //if the enemy is already being respawned, stop
    gotHit = true; //indicate, that the enemy is being respawned
    playAnimation("hit");
    velocity = Vector3.zero(); //reset velocity
    setGravityEnabled(false); //temporarily disable gravity for this enemy

    await Future.delayed(
      Duration(milliseconds: 250),
    ); //wait a quarter of a second for the animation to finish
    position -= Vector2.all(
      32,
    ); //center the enemy so that the animation displays correctly (its 96*96 and the enemy is 32*32)
    scale.x =
        1; //flip the enemy to the right side and a third of the size because the animation is triple of the size
    current = playAnimation("disappearing"); //display a disappear animation
    await Future.delayed(
      Duration(milliseconds: 320),
    ); //wait for the animation to finish
    position =
        startingPosition -
        Vector2(
          40,
          32,
        ); //position the enemy at the spawn point and also add the displacement of the animation
    scale = Vector2.all(0); //hide the enemy
    await Future.delayed(
      Duration(milliseconds: 800),
    ); //wait a bit for the camera to position and increase the annoyance of the player XD
    scale = Vector2.all(1); //show the enemy
    current = playAnimation("appearing"); //display an appear animation
    await Future.delayed(
      Duration(milliseconds: 300),
    ); //wait for the animation to finish

    updatePlayerstate(); //update the enemies feet to the ground
    gotHit = false; //indicate, that the respawn process is over
    position += Vector2.all(
      32,
    ); //reposition the enemy, because it had a bit of displacement because of the respawn animation
    setGravityEnabled(true); //re-enable gravity
  }

  @override
  ShapeHitbox? getHitbox() => hitbox;

  @override
  Vector2 getPosition() => position;

  @override
  Vector2 getScale() => scale;

  bool climbing = false;

  @override
  void setClimbing(bool val) => climbing = val;

  @override
  bool get isClimbing => climbing;

  @override
  bool get isTryingToGetDownLadder {
    return isShifting;
  }

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
  String get componentSpriteLocation => "Main Characters/Virtual Guy";

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.entity;

  @override
  bool get isInHitFrames => gotHit;

  @override
  bool get isInRespawnFrames => isRespawning;
}
