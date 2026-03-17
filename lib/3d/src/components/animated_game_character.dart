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
    double playAmount = 1.0,
  }) async {
    assert(
      playAmount >= 0 && playAmount <= 1,
      "playAmount must be within [0, 1], got $playAmount",
    );

    if (currentAnimation == name && !restartIfAlreadyPlaying) return;

    _animationSequence++;
    final int currentSeq = _animationSequence;
    currentAnimation = name;

    // fill cache
    await _ensureAnimationCache();
    if (currentSeq != _animationSequence) return;
    // Both of these are on ThermionAsset — wait parameter is only available in FFIasset
    final index = _animationDurations!.keys.toList().indexOf(name);
    if (index == -1) throw Exception("Animation '$name' not found");
    print("Calling playGltfAnimation index=$index on entity=${asset.entity}, loop=$loop");
    await asset.playGltfAnimation(
      index,
      loop: loop,
      replaceActive: replaceActive,
      reverse: reverse,
      speed: speed,
      crossfade: crossfade,
    );
    print("AFTER playGltfAnimation — success");

    if (!loop) {
      if (currentSeq != _animationSequence) return;

      final durationSecs = _animationDurations![name]!;
      final ms = (durationSecs * 1000 * playAmount / speed).toInt();

      await Future.delayed(Duration(milliseconds: ms + 16));

      if (currentSeq == _animationSequence) currentAnimation = "";
    }
  }

  Future<void> stopAnimation(String name) async {
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
