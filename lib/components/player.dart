import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:mpg_achievements_app/components/state_management/providers/playerStateProvider.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/components/level_components/checkpoint/checkpoint.dart';
import 'package:mpg_achievements_app/components/level_components/collectables.dart';
import 'package:mpg_achievements_app/components/level_components/enemy.dart';
import 'package:mpg_achievements_app/components/physics/movement_collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'level_components/saw.dart';
//todo implement PlayerStateProvider to manage the player state globally
//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with
        HasGameReference<PixelAdventure>,
        RiverpodComponentMixin,
        KeyboardHandler,
        CollisionCallbacks,
        HasCollisions,
        BasicMovement,
        KeyboardControllableMovement,
        AnimationManager,
        HasMovementAnimations,
        JoystickControllableMovement

         {
  //bools
  bool debugNoClipMode = false;
  bool debugImmortalMode = false;
  //we need this local state flag because of the animation and movement logic, it refers to the global state bool gotHit
  bool _isHitAnimationPlaying = false;
  bool _isRespawningAnimationPlaying = false;
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
  void update(double dt) {
    super.update(dt);

    //Provider logic follow
    //the ref.watch here makes sure that the player component rebuilds and PlayerData changes its values when the player state changes
    final playerState = ref.watch(playerProvider);


    //Hit-Logic
    //if the player is respawning we play the respawn animation and call the respawn logic when it is complete
    if(playerState.isRespawning && !_isRespawningAnimationPlaying){
      _isRespawningAnimationPlaying = true;

      playAnimation('hit').whenComplete((){

        //this is called when the hit animation is complete
        ref.read(playerProvider.notifier).resetHit();
        //now we call the respawn logic
        _respawn();
      });
      }

    //Respawn logic
    //if the player got hit and the hit animation is not already playing we play the hit animation and reset the gotHit state when it is complete
    else if (playerState.gotHit && !_isHitAnimationPlaying) {
      //if the player has no lives left, we respawn them
      _isHitAnimationPlaying = true;
      playAnimation('hit').whenComplete(() {

        ref.read(playerProvider.notifier).resetHit();
        _isHitAnimationPlaying = false;
      });

      }

  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyR)) {
      ref.read(playerProvider.notifier).manualRespawn();
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

    if (other is Saw && !debugImmortalMode) {
      ref.read(playerProvider.notifier).takeHit();}

    if (other is Enemy && !debugImmortalMode) {
      ref.read(playerProvider.notifier).takeHit();}

    if (other is Collectable && other.interactiveTask) {
      //todo state management for tasks
      game.showDialogue = true;
      game.overlays.add('DialogueScreen');
    }
    super.onCollision(intersectionPoints, other);
  }

  void _respawn() async {

    updateMovement = false;
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
    await playAnimation("disappearing"); //display a disappear animation
    await Future.delayed(
      Duration(milliseconds: 320),
    );
    //wait for the animation to finish

    // respawn position is the last checkpoints position

    //Positioning the player after respawn
    final respawnPoint = ref.read(playerProvider).lastCheckpoint;

    position = (respawnPoint?.position ?? startingPosition) - Vector2(40,32);

    //position the player at the spawn point and also add the displacement of the animation
    scale = Vector2.all(0); //hide the player
    await Future.delayed(
      Duration(milliseconds: 800),
    ); //wait a bit for the camera to position and increase the annoyance of the player XD
    scale = Vector2.all(1); //show the player
    await playAnimation("appearing"); //display an appear animation

    await Future.delayed(
      Duration(milliseconds: 300),
    );

    //wait for the animation to finish
    //todo renaming necessary
    setGravityEnabled(true);
    print("reenabled gravity");//re-enable gravity
    updateMovement = true;
    updatePlayerstate(); //update the players feet to the ground
    position += Vector2.all(
      32,
    ); //reposition the player, because it had a bit of displacement because of the respawn animation


    ref.read(playerProvider.notifier).completeRespawn();
    _isRespawningAnimationPlaying = false;
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

  //we answer the getters from HasMovementAnimations here to tell the mixin if we are currently in hit or respawn frames
  @override
  bool get isInHitFrames => _isHitAnimationPlaying;
  bool get isInRespawnFrames => _isRespawningAnimationPlaying;



  }
