import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:mpg_achievements_app/components/animation/CharacterStateManager.dart';
import 'package:mpg_achievements_app/components/collectables.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'traps/saw.dart';




//using SpriteAnimationGroupComponent is better for a lot of animations
//with is used to additonal classes here our game class
//import/reference to Keyboardhandler
class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>,
        KeyboardHandler,
        CollisionCallbacks, HasCollisions,
        BasicMovement, KeyboardControllableMovement, CharacterStateManager{


  bool debugNoClipMode = false;
  bool debugImmortalMode = false;

  bool gotHit = false;

  //starting position
  Vector2 startingPosition = Vector2.zero();

  // because the hitbox is a property of the player it follows the player where ever he goes. Same for the collecables
  RectangleHitbox hitbox = RectangleHitbox(
    position: Vector2(4, 4),
    size: Vector2(24, 28),
  );


  //constructor super is reference to the SpriteAnimationGroupComponent above, which contains position as attributes
  Player({required String playerCharacter, super.position}){
    character = playerCharacter;
  }

  @override
  FutureOr<void> onLoad() {
    //using an underscore is making things private
    startingPosition = Vector2(position.x, position.y);
    add(hitbox);
    return super.onLoad();
  }

  //dt means deltatime and is adjusting the framspeed to make game playable even tough there might be high framrates
  @override
  void update(double dt) {
    super.update(dt);
  }


  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyR)) _respawn(); //press r to reset player
    if (keysPressed.contains(LogicalKeyboardKey.keyX)) print(hitbox.isColliding); //press x to print if the player is currently in a wall
    if (keysPressed.contains(LogicalKeyboardKey.keyC)) {debugNoClipMode = !debugNoClipMode; setDebugNoCipMode(debugNoClipMode);}; //press C to toggle noClip mode. lets you fall / walk / fly through walls. better only use it whilst flying (ctrl key)
    if (keysPressed.contains(LogicalKeyboardKey.keyY)) debugImmortalMode = !debugImmortalMode; //press Y to toggle immortality

    return super.onKeyEvent(event, keysPressed);
  }

  //checking collisions with an inbuilt method that checks if player is colliding
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    //here the player checks if the hitbox that it is colliding with is a Collectable or saw, if so it calls the collidedWithPlayer method of class Collectable
    if (other is Collectable) other.collidedWithPlayer();
    if (other is Saw && !debugImmortalMode) _respawn();
    super.onCollision(intersectionPoints, other);
  }

  void _respawn() async{
    if (gotHit) return; //if the player is already being respawned, stop
    gotHit = true; //indicate, that the player is being respawned
    current = PlayerState.hit; //hit animation
    velocity = Vector2.zero(); //reset velocity
    setGravityEnabled(false); //temporarily disable gravity for this player

    await Future.delayed(Duration(milliseconds: 250)); //wait a quarter of a second for the animation to finish
    position -= Vector2.all(32); //center the player so that the animation displays correctly (its 96*96 and the player is 32*32)
    scale.x = 1; //flip the player to the right side and a third of the size because the animation is triple of the size
    current = PlayerState.disappearing; //display a disappear animation
    await Future.delayed(Duration(milliseconds: 320)); //wait for the animation to finish
    position = startingPosition - Vector2(40,32); //position the player at the spawn point and also add the displacement of the animation
    scale = Vector2.all(0); //hide the player
    await Future.delayed(Duration(milliseconds: 800)); //wait a bit for the camera to position and increase the annoyance of the player XD
    scale = Vector2.all(1); //show the player
    current = PlayerState.appearing; //display an appear animation
    await Future.delayed(Duration(milliseconds: 300)); //wait for the animation to finish

    updatePlayerstate(); //update the players feet to the ground
    gotHit = false; //indicate, that the respawn process is over
    position += Vector2.all(32); //reposition the player, because it had a bit of displacement because of the respawn animation
    setGravityEnabled(true); //re-enable gravity
  }

  @override
  ShapeHitbox getHitbox() => hitbox;

  @override
  Vector2 getPosition() => position;

  @override
  Vector2 getScale() => scale;

  @override
  Vector2 getVelocity() => velocity;

  @override
  void setIsOnGround(bool val) => isOnGround = val;

  @override
  void setPos(Vector2 newPos) => position = newPos;

  @override
  bool isInHitFrames() => gotHit; //if the player is currently getting respawned

  @override
  String getCharacter() => character;
}