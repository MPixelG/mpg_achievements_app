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
  //prohibit timer conflicts
  int _animationSequence = 0;
  String currentAnimation = "";
  //store animationDurations
  Map<String, double>? _animationDurations;

  //needs to be Future because because otherwise await does not work
  Future<void> playAnimation(
    String name, {
    bool loop = false,
    bool replaceActive = true,
    bool restartIfAlreadyPlaying = false,
    bool reverse = false,
    double speed = 1.0,
    double crossfade = 0.5,
    double playAmount = 1,
  }) async {

    assert(
    playAmount <= 1 && playAmount >= 0,
    "playAmount must be within the bounds of 0 and 1! currently it is $playAmount",
    );
    //prohibit new start of animation if not necessary
    if (currentAnimation == name && !restartIfAlreadyPlaying) return;

    _animationSequence++;
    final int currentSeq = _animationSequence; //save current loop
    currentAnimation = name;

    await asset.playGltfAnimationByName(
      name,
      loop: loop,
      replaceActive: replaceActive,
      reverse: reverse,
      speed: speed,
      crossfade: crossfade,
    );
    // get out early if superseded by animation
    if (currentSeq != _animationSequence) return;

    if (!loop) {
      //get animationDuration from map, helps with duration calls every loop
      await _ensureAnimationCache();
      final durationSeconds = _animationDurations![name] ?? 0.0;
      final ms = (durationSeconds * 1000 * playAmount).toInt();

      await Future.delayed(Duration(milliseconds: ms));

      if (currentSeq == _animationSequence) currentAnimation = "";
    }
  }

  void stopAnimation(String name) {
    asset.stopGltfAnimationByName(name);
    currentAnimation = "";
  }

  Future<void> _ensureAnimationCache() async {
    if (_animationDurations != null) return;
    final names = await asset.getGltfAnimationNames();
    _animationDurations = {};
    for (int i = 0; i < names.length; i++) {
      _animationDurations![names[i]] = await asset.getGltfAnimationDuration(i);
    }
  }

  Future<List<String>> getAnimationNames() => asset.getGltfAnimationNames();
}
