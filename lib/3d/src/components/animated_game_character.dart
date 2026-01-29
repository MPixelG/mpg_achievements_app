
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
  String currentAnimation = "";
  void playAnimation(String name, {bool loop = false, bool replaceActive = true, bool restartIfAlreadyPlaying = false, bool reverse = false, double speed = 1.0, double crossfade = 0.2}){
    if(currentAnimation == name && !restartIfAlreadyPlaying) return;
    asset.playGltfAnimationByName(name, loop: loop, replaceActive: replaceActive, reverse: reverse, speed: speed, crossfade: crossfade);
    currentAnimation = name;
  } 
  
  void stopAnimation(String name){
    asset.stopGltfAnimationByName(name);
    currentAnimation = "";
  }
  
  Future<List<String>> getAnimationNames() => asset.getGltfAnimationNames();
    
}