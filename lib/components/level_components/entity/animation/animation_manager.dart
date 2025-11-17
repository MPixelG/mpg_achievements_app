import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level_components/entity/animation/animated_character.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

mixin AnimationManager on AnimatedCharacter, HasGameReference<PixelAdventure> {
  final double stepTime = 0.05; //the time for every frame

  String get componentSpriteLocation; //the path to the objects animations

  AnimatedComponentGroup get group; //if its an entity or unmovable object

  final Map<String, String> animationNames = {};

  bool initialized = false;

  ///lets you re-map your animation names. for example if your running animation isnt named "running", you can change the animation for that here!
  ///example: use setCustomAnimationName("idle", "doingNothing") so that it uses "doingNothing" as an idle animation
  void setCustomAnimationName(String realName, String mappedName) {
    if (!initialized) {
      animationNamesToAddOnInitialized ??= [];
      animationNamesToAddOnInitialized!.add(MapEntry(realName, mappedName));
    } else {
      animationNames[realName] = mappedName;
    }
  }

  List<MapEntry<String, String>>?
  animationNamesToAddOnInitialized; //a function that is called when the animations are initialized

  ///takes a animation you want to play (for example "idle") and gives you the used animation name for that. this way you can change animations.
  String getAnimation(String name) {
    if (!initialized) {
      //if we haven't loaded the animations yet, we load them in the background and return "idle" for that frame
      _loadAnimations();
      return "idle";
    }

    final String? converted = animationNames[name];

    assert(converted != null, "animation $name not registered!");

    return converted!;
  }

  ///plays the animation. its async so you can put an await before the method call so that you wait until its over
  Future<void> playAnimation(String name) async {
    if (!initialized) await _loadAnimations();
    current = animationNames[name];
    return animationTicker?.completed;
  }

  List<AnimationLoadOptions>
  get animationOptions; //so that you can provide the different options

  Future<void> _loadAnimations() async {
    if (initialized) return;

    final Map<String, SpriteAnimation> newAnimations = {
      //create a new map of animation names and the animations
      for (var option in animationOptions)
        option.name: loadAnimation(
          option.name,
          path: option.path,
          frames: option.frames,
          loop: option.loop,
          textureSize: option.textureSize,
          stepTime: option.stepTime,
        ),
    };

    animations = newAnimations; //update the animation map
    initialized = true;
    if (animationNamesToAddOnInitialized != null) {
      animationNames.addEntries(animationNamesToAddOnInitialized!);
    }
  }

  SpriteAnimation loadAnimation(
    String name, {
    required String path,
    int? frames,
    double stepTime = 0.05,
    bool loop = true,
    double textureSize = 32,
  }) {
    final Image image = game.images.fromCache(
      "$path ${getTextureSizeFileEnding(textureSize)}",
    ); //load the image with the path and the right file ending (bsp: " (32x32) .png")

    animationNames[name] =
        name; //map it. this can be changed later to set a different animation for sth

    return SpriteAnimation.fromFrameData(
      image, //the image containing the animation frames as a spritesheet
      SpriteAnimationData.sequenced(
        amount:
            frames ??
            (image.width / textureSize)
                .toInt(), //if we dont have the amount of frames of the animation, we calculate it by using the full texture width and the single frame width
        stepTime: stepTime,
        textureSize: Vector2.all(textureSize),
        loop: loop,
      ),
    );
  }

  ///formats a given double to a file ending including the format
  String getTextureSizeFileEnding(
    double textureSize, {
    String fileFormat = "png",
  }) {
    final int intTextureSize = textureSize.toInt(); //convert it to an int

    return "(${intTextureSize}x$intTextureSize).$fileFormat"; //and add brackets and the file type
  }
}

class AnimationLoadOptions {
  //options for creating an animation

  String name; //the name the animation is registered of
  String path; //the path to the animation
  int?
  frames; //the amount of frames. if nothing is provided, it will get calculated using the image width and single frame width
  double stepTime; //the time for every frame
  bool loop; //if it loops
  double textureSize; //the size of the texture

  AnimationLoadOptions(
    this.name,
    this.path, {
    this.frames,
    this.stepTime = 0.05,
    this.loop = true,
    this.textureSize = 32,
  });
}

enum AnimatedComponentGroup {
  entity,
  object,
  effect, //for later use, indicates if the object changes in some vals or not.
}

// Isometrische Richtungen für 8-Richtungenewegung
enum IsoDirection {
  s, // South (unten)
  se, // South-East (rechtsunten)
  e, // East (rechts)
  ne, // North-East (rechtsoben)
  n, // North (oben)
  nw, // North-West (linkoben)
  w, // West (links)
  sw, // South-West (linksunten)
}

mixin HasMovementAnimations on AnimationManager {
  //current character face direction
  final IsoDirection _currentDirection = IsoDirection.s;
  IsoDirection get currentDirection => _currentDirection;

  IsoDirection calculateIsoDirection(Vector3 velocity) {
    if (velocity.x == 0 && velocity.z == 0) {
      return _currentDirection;
    }

    //calcualte angle
    double angle = math.atan2(velocity.z, velocity.x) * 180 / math.pi;
    if (angle < 0) angle += 360;
    return IsoDirection.e;
  }

  List<AnimationLoadOptions> get movementAnimationDefaultOptions => [
    AnimationLoadOptions(
      "idle",
      "$componentSpriteLocation/Idle",
    ), //some pre-defined animations for movement
    AnimationLoadOptions("running", "$componentSpriteLocation/Run"),
    AnimationLoadOptions("jumping", "$componentSpriteLocation/Jump"),
    AnimationLoadOptions("falling", "$componentSpriteLocation/Fall"),
  ];

  bool
  get isInHitFrames; //if the player is currently being hit, we dont want to overwrite the animation
  bool
  get isInRespawnFrames; //if the player is currently respawning, we dont want to overwrite the animation

  @override
  void update(double dt) {
    updatePlayerstate();
    super.update(dt);
  }

  //todo renaming necessary
  void updatePlayerstate() {
    if (isInRespawnFrames || isInHitFrames) {
      return; //if we are in respawn or hit frames we dont want to change the animation
    }

    String animation = getAnimation("idle");

    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    if (velocity.x < -1 && scale.x > 0) {
      scale.x = -scale.x;
    } else if (velocity.x > 1 && scale.x < 0) {
      scale.x = -scale.x;
    }
    //Check if moving
    if (velocity.x > 4 ||
        velocity.x < -4 ||
        velocity.z > 4 ||
        velocity.z < -4) {
      animation = getAnimation("running");
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 4) animation = getAnimation("jumping");

    if (velocity.y < -4) animation = getAnimation("falling");

    //here the animation ist set after checking all of the conditions above
    playAnimation(animation);
  }
}
