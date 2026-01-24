
import 'game_character.dart';

abstract class AnimatedGameCharacter<TState> extends GameCharacter<TState> {
  AnimatedGameCharacter({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    required super.modelPath,
    super.name,
  });
  
  void playAnimation(String name, {bool loop = false, bool replaceActive = true, bool reverse = false, double speed = 1.0, double crossfade = 0.0}){
    asset.playGltfAnimationByName(name, loop: loop, replaceActive: replaceActive, reverse: reverse, speed: speed, crossfade: crossfade);
  }  
  
  void stopAnimation(String name){
    asset.stopGltfAnimationByName(name);
  }
  
  Future<List<String>> getAnimationNames() => asset.getGltfAnimationNames();
  
}