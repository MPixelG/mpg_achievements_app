import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/physics/movement_collisions.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

mixin AnimationManager on SpriteAnimationGroupComponent, HasGameReference<PixelAdventure>{

  final double stepTime = 0.05; //the time for every frame

  String get componentSpriteLocation; //the path to the objects animations

  AnimatedComponentGroup get group; //if its an entity or unmovable object

  final Map<String, String> animationNames = {};
  ///lets you re-map your animation names. for example if your running animation isnt named "running", you can change the animation for that here!
  ///example: use setCustomAnimationName("idle", "doingNothing") so that it uses "doingNothing" as an idle animation
  void setCustomAnimationName(String realName, String mappedName) => animationNames[realName] = mappedName;


  ///takes a animation you want to play (for example "idle") and gives you the used animation name for that. this way you can change animations.
  String getAnimation(String name) {
    if(animationNames.isEmpty) { //if we havent loaded the animations yet, we load them in the background and return "idle" for that frame
      _loadAnimations();
      return "idle";
    }

    String? converted = animationNames[name];

    assert(converted != null, "animation $name not registered!");

    return converted!;
  }


  ///plays the animation. its async so you can put an await before the method call so that you wait until its over
  Future<void> playAnimation(String name) async{
    if(animations == null) await _loadAnimations();
    current = animationNames[name];
    return animationTicker?.completed;
  }

  List<AnimationLoadOptions> get animationOptions; //so that you can provide the different options

  Future<void> _loadAnimations() async{
    Map<String, SpriteAnimation> newAnimations = { //create a new map of animation names and the animations
      for (var option in animationOptions)
        option.name : loadAnimation(option.name, path: option.path, frames: option.frames, loop: option.loop, textureSize: option.textureSize, stepTime: option.stepTime),
    };

    animations = newAnimations; //update the animation map
  }


  SpriteAnimation loadAnimation(String name, {required String path, int? frames, double stepTime = 0.05, bool loop = true, double textureSize = 32}){
    Image image = game.images.fromCache("$path ${getTextureSizeFileEnding(textureSize)}"); //load the image with the path and the right file ending (bsp: " (32x32) .png")

    animationNames[name] = name; //map it. this can be changed later to set a different animation for sth

    return SpriteAnimation.fromFrameData(
      image, //the image containing the animation frames as a spritesheet
      SpriteAnimationData.sequenced(
        amount: frames ?? (image.width / textureSize).toInt(), //if we dont have the amount of frames of the animation, we calculate it by using the full texture width and the single frame width
        stepTime: stepTime,
        textureSize: Vector2.all(textureSize),
        loop: loop,
      ),
    );
  }

  ///formats a given double to a file ending including the format
  String getTextureSizeFileEnding(double textureSize, {String fileFormat = "png"}){
    int intTextureSize = textureSize.toInt(); //convert it to an int

    return "(${intTextureSize}x$intTextureSize).$fileFormat";  //and add brackets and the file type
  }


}

class AnimationLoadOptions{ //options for creating an animation

  String name; //the name the animation is registered of
  String path; //the path to the animation
  int? frames; //the amount of frames. if nothing is provided, it will get calculated using the image width and single frame width
  double stepTime; //the time for every frame
  bool loop; //if it loops
  double textureSize; //the size of the texture

  AnimationLoadOptions(this.name, this.path, {this.frames, this.stepTime = 0.05, this.loop = true, this.textureSize = 32});
}


enum AnimatedComponentGroup {
  entity, object //for later use, indicates if the object changes in some vals or not.
}


mixin HasMovementAnimations on AnimationManager, BasicMovement{

  List<AnimationLoadOptions> get movementAnimationDefaultOptions => [
    AnimationLoadOptions("idle", "$componentSpriteLocation/Idle", loop: true, textureSize: 32), //some pre-defined animations for movement
    AnimationLoadOptions("running", "$componentSpriteLocation/Run", loop: true, textureSize: 32),
    AnimationLoadOptions("jumping", "$componentSpriteLocation/Jump", loop: true, textureSize: 32),
    AnimationLoadOptions("falling", "$componentSpriteLocation/Fall", loop: true, textureSize: 32),
  ];


  bool get isInHitFrames; //if the player is currently being hit, we dont want to overwrite the animation

  @override
  void update(double dt){

    if(!isInHitFrames) updatePlayerstate();
    animationTicker?.update(dt);

    super.update(dt);

  }

  void updatePlayerstate() {

    String animation = getAnimation("idle");

    //if we are going to the right and facing left flip us and the other way round
    //if the velocity is less than 2 we don't animate bc the movement is too slow and not noticeable
    if (velocity.x < -1 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 1 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }
    //Check if moving
    if (velocity.x > 1 || velocity.x < -1) {
      animation = getAnimation("running");
    }

    // update state to falling if velocity is greater than 0
    if (velocity.y > 0) animation = getAnimation("falling");

    if (velocity.y < 0) animation = getAnimation("jumping");

    //here the animation ist set after checking all of the conditions above
    playAnimation(animation);
  }


}