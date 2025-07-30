import 'dart:async';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/physics/collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

//an enumeration of all of the states a player can be in , here we declare the enum outside of our class
//the values can be used like static variables
enum PlayerState { idle, running, jumping, falling, hit, appearing, disappearing }

mixin CharacterStateManager on SpriteAnimationGroupComponent, BasicMovement, HasGameReference<PixelAdventure>{

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearAnimation;
  late final SpriteAnimation disappearAnimation;

  //50ms or 20 fps or 0.05s this is reference from itch.io
  final double stepTime = 0.05;

  late String character;

  late String pathPlayer;
  String pathRespawn = 'Main Characters/';
  double textureSize32 = 32;
  double textureSize96 = 96;
  String texture32file = '(32x32).png';
  String texture96file = '(96x96).png';

  @override
  FutureOr<void> onLoad() {
    character = getCharacter();
    pathPlayer = 'Main Characters/$character/';

    loadAllAnimations();

    return super.onLoad();
  }
  @override
  void update(double dt) {
    if(!isInHitFrames()) updatePlayerstate();
    super.update(dt);

    animationTicker?.update(dt);
  }

  bool isInHitFrames();
  String getCharacter();

  void loadAllAnimations() {
    //this takes an image from the assets folder and also enables us to set some specifics like texture size and how we want to split up our animation and get them from cache
    // where we loaded them at the beginning -> needs to be cleaned up only quick and dirty fix
    idleAnimation = _spriteAnimation(pathPlayer,'Idle ', 11, true, texture32file, textureSize32);
    runningAnimation = _spriteAnimation(pathPlayer,'Run ', 12, true, texture32file, textureSize32);
    fallingAnimation = _spriteAnimation(pathPlayer,'Fall ', 1, true, texture32file, textureSize32);
    jumpingAnimation = _spriteAnimation(pathPlayer,'Jump ', 1, true, texture32file, textureSize32);
    hitAnimation = _spriteAnimation(pathPlayer,'Hit ', 7, false, texture32file, textureSize32);
    appearAnimation = _spriteAnimation(pathRespawn,'Appearing ', 7, false, texture96file, textureSize96);
    disappearAnimation = _spriteAnimation(pathRespawn,'Disappearing ', 7, false, texture96file, textureSize96);


    //List of all animations
    animations = {
      //here this state is equal our idleAnimation from above
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearAnimation,
      PlayerState.disappearing: disappearAnimation,
    };

    //set current animation
    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String path, String state, int amount, bool loop, String fileName, double textureSize) =>
      SpriteAnimation.fromFrameData(
        game.images.fromCache('$path$state$fileName' ),
        SpriteAnimationData.sequenced(
          //11 image in the Idle.png
          amount: amount,
          stepTime: stepTime,
          textureSize: Vector2.all(textureSize),
          loop: loop,
        ),
      );

  void updatePlayerstate() {
    PlayerState playerState = PlayerState.idle;
    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    if (velocity.x < -1 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 1 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 1 || velocity.x < -1) {
      playerState = PlayerState.running;
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 0) playerState = PlayerState.falling;

    if (velocity.y < 0) playerState = PlayerState.jumping;

    //here the animation ist set after checking all of the conditions above
    current = playerState;
  }
}