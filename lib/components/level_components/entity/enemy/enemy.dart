import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level_components/entity/animation/animated_character.dart';
import 'package:mpg_achievements_app/components/level_components/saw.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';
import '../animation/animation_manager.dart';
import 'ai/goals/follow_player_goal.dart';
import 'ai/goals/goal_manager.dart';
import 'ai/goals/move_goal.dart';
import 'ai/goals/pathtracing_goal.dart';
import 'ai/goals/player_locating_goal.dart';

class Enemy extends AnimatedCharacter
    with
        KeyboardHandler,
        CollisionCallbacks,
        AnimationManager,
        HasMovementAnimations {
  bool gotHit = false;
  bool isRespawning = false;

  //debug switches for special modes
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;

  //starting position
  Vector3 startingPosition = Vector3.zero();
  String enemyCharacter;

  //constructor super is reference to the SpriteanimationGroupComponent above, which contains position as attributes
  Enemy({
    required this.enemyCharacter,
    super.position,
    super.anchor = Anchor3D.center,
  }) : super(size: Vector3(1, 1, 1));

  late GoalManager manager;
  @override
  FutureOr<void> onLoad() {
    startingPosition = position.clone();
    // The player inspects its environment (the level) and configures itself.
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
  void _respawn() async {
    if (gotHit) return; //if the enemy is already being respawned, stop
    gotHit = true; //indicate, that the enemy is being respawned
    playAnimation("hit");
    velocity = Vector3.zero(); //reset velocity

    await Future.delayed(
      Duration(milliseconds: 250),
    ); //wait a quarter of a second for the animation to finish
    position -= Vector3.all(
      32,
    ); //center the enemy so that the animation displays correctly (its 96*96 and the enemy is 32*32)
    scale.x = 1; //flip the enemy to the right side and a third of the size because the animation is triple of the size
    current = playAnimation("disappearing"); //display a disappear animation
    await Future.delayed(
      Duration(milliseconds: 320),
    ); //wait for the animation to finish
    position =
        startingPosition -
        Vector3.all(32); //position the enemy at the spawn point and also add the displacement of the animation
    scale = Vector3.all(0); //hide the enemy
    await Future.delayed(
      Duration(milliseconds: 800),
    ); //wait a bit for the camera to position and increase the annoyance of the player XD
    scale = Vector3.all(1); //show the enemy
    current = playAnimation("appearing"); //display an appear animation
    await Future.delayed(
      Duration(milliseconds: 300),
    ); //wait for the animation to finish

    updatePlayerstate(); //update the enemies feet to the ground
    gotHit = false; //indicate, that the respawn process is over
    position += Vector3.all(
      32,
    ); //reposition the enemy, because it had a bit of displacement because of the respawn animation
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
