import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';

class AnimatedGameTexture extends GameTexture {
  AnimatedGameTexture.fromMetadata(super.metadata, super.basePath) : super.fromMetadata();
  AnimatedGameTexture.fromPath(String assetPath) : super.fromPath(assetPath: assetPath);

  late int frames;
  late AnimationType animationType;
  late AnimationDirection animationDirection;


  @override
  void registerExtra(Map<String, dynamic> metadata) {
    assert(metadata.containsKey("animation"));
    final animationData = metadata["animation"];
    frames = animationData["frames"] ?? 1;
    animationType = switch (animationData["type"] ?? "loop") {
      "loop" => AnimationType.loop,
      "pingPong" => AnimationType.pingPong,
      "once" => AnimationType.once,
      _ => AnimationType.loop,
    };
    animationDirection = switch (animationData["direction"] ?? "horizontal") {
      "horizontal" => AnimationDirection.horizontal,
      "vertical" => AnimationDirection.vertical,
      _ => AnimationDirection.horizontal,
    };
    super.registerExtra(metadata);
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