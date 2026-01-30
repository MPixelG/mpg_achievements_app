

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
  void playAnimation(String name, {bool loop = false, bool replaceActive = true, bool restartIfAlreadyPlaying = false, bool reverse = false, double speed = 1.0, double crossfade = 0.5, double playAmount = 1}) async {
    if(currentAnimation == name && !restartIfAlreadyPlaying) return;
    currentAnimation = name;
    await asset.playGltfAnimationByName(name, loop: loop, replaceActive: replaceActive, reverse: reverse, speed: speed, crossfade: crossfade);
    if(!loop) {
      assert(playAmount <= 1 && playAmount >= 0, "playAmount must be within the bounds of 0 and 1! currently it is $playAmount");
      await Future.delayed(Duration(milliseconds: (await asset.getGltfAnimationDuration((await asset.getGltfAnimationNames()).indexOf(name)) * 1000 * playAmount).toInt()));
      if(currentAnimation == name) currentAnimation = "";
    }
  } 
  
  void stopAnimation(String name){
    asset.stopGltfAnimationByName(name);
    currentAnimation = "";
  }
  
  Future<List<String>> getAnimationNames() => asset.getGltfAnimationNames();
    
}