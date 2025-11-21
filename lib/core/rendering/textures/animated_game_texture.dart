import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';

class AnimatedGameTexture extends GameTexture {
  int frames;
  late AnimationType animationType;
  late AnimationDirection animationDirection;
  AnimatedGameTexture(super.spritesheet, super.depthSpritesheet, super.name, super.srcPos, super.size, super.direction, this.frames, {String? animationType, String? animationDirection}){
    this.animationType = switch(animationType){
      "loop" => AnimationType.loop,
      "pingPong" => AnimationType.pingPong,
      "once" => AnimationType.once,
      _ => AnimationType.loop,
    };
    this.animationDirection = switch(animationDirection){
      "horizontal" => AnimationDirection.horizontal,
      "vertical" => AnimationDirection.vertical,
      _ => AnimationDirection.horizontal,
    };
  }
}

enum AnimationType {
  loop,
  pingPong,
  once,
}
enum AnimationDirection {
  horizontal,
  vertical,
}