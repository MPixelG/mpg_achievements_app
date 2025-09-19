import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/animation/animation_manager.dart';
import 'package:mpg_achievements_app/components/level/isometric/tile_effects/highlighted_tile.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import '../isometric_renderable.dart';
import '../isometric_tiled_component.dart';

class ExplosionEffect extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, AnimationManager, IsometricRenderable {

  final Vector2 gridPos;
  TileHighlightRenderable tileHighlight;
  int initZIndex;
  int? currentZIndex;

  ExplosionEffect(this.tileHighlight, this.initZIndex, this.gridPos) {
    currentZIndex = initZIndex;
    print("__________________new instance created!");
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.bottomCenter;
    currentZIndex = initZIndex;
    // The explosion's visual center should align with its position.
    // Play the animation once, and when it's complete, remove this component.
    playAnimation('explosion_1');
  }

  bool done = false;
  @override
  void update(double dt) {
    super.update(dt);
    var ticker = animationTicker;
    if (ticker != null){

      int frameIndex = ticker.currentIndex;
      currentZIndex = initZIndex + frameIndex;
    }

    ticker?.onComplete = () {
      done = true;
      (game.gameWorld.level as IsometricTiledComponent).forceRebuildCache();
    };
  }

  @override
  AnimatedComponentGroup get group => AnimatedComponentGroup.entity;

  @override
  String get componentSpriteLocation => 'Explosions/explosion1d';

  @override
  List<AnimationLoadOptions> get animationOptions => [
    AnimationLoadOptions(
      "explosion_1",
      "$componentSpriteLocation/explosion1d", // Use the path directly
      textureSize: 128,
      loop: false,
      stepTime: 0.1,
    ),
  ];

  @override
  Vector2 get gridFeetPos => tileHighlight.gridPos;

  @override
  RenderCategory get renderCategory => RenderCategory.effect;

  @override
  int get renderPriority => currentZIndex ?? 1;
}