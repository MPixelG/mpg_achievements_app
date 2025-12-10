import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:mpg_achievements_app/components/animation/game_sprite_animation_ticker.dart';
import 'package:mpg_achievements_app/components/level_components/entity/game_character.dart';
import 'package:mpg_achievements_app/core/math/notifying_vector_3.dart';
import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';
import 'package:mpg_achievements_app/core/rendering/textures/game_texture_batch.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

abstract class AnimatedCharacter extends GameCharacter with HasPaint{
  /// Key with the current playing animation
  String? _current;

  ValueNotifier<String?>? _currentAnimationNotifier;

  /// A [ValueNotifier] that notifies when the current animation changes.
  ValueNotifier<String?> get currentAnimationNotifier =>
      _currentAnimationNotifier ??= ValueNotifier<String?>(_current);

  /// Map with the mapping each state to the flag removeOnFinish
  final Map<String, bool> removeOnFinish;

  /// Map with the available states for this animation group
  GameTextureBatch? _textureBatch;
  String name;
  
  GameTextureBatch? get textureBatch => _textureBatch;
  
  set textureBatch(GameTextureBatch? newTextureBatch){
    _textureBatch = newTextureBatch;
    updateAnimationTickers();
  }

  /// Map containing animation tickers for each animation state.
  Map<String, Map<double? ,GameSpriteAnimationTicker>>? _animationTickers;

  /// Whether the animation is paused or playing.
  bool playing;

  /// When set to true, the component is auto-resized to match the
  /// size of current animation sprite.
  bool _autoResize;

  /// Whether the current animation's ticker should reset to the beginning
  /// when it becomes current.
  bool autoResetTicker;

  /// Creates a component with an empty animation which can be set later
  AnimatedCharacter({
    GameTextureBatch? textureBatch,
    required this.name,
    String? current,
    bool? autoResize,
    this.playing = true,
    this.removeOnFinish = const {},
    this.autoResetTicker = true,
    Paint? paint,
    super.position,
    required super.size,
    super.scale,
    super.anchor,
    super.children,
    super.priority,
    super.key,
  }) :  _current = current,
        _autoResize = autoResize ?? true,
        _textureBatch = textureBatch
        {
    if (paint != null) {
      this.paint = paint;
    }

    /// Register a listener to differentiate between size modification done by
    /// external calls v/s the ones done by [_resizeToSprite].
    size.addListener(_handleAutoResizeState);
    updateAnimationTickers();
    
    _resizeToSprite();
  }
  
  void updateAnimationTickers(){
    final Map<String, Map<double?, GameSpriteAnimationTicker>> newTickers = {};
    textureBatch?.textures.forEach(
            (key, value) => value.forEach(
                (direction, value) {
                  newTickers[key] ??= {};
                  newTickers[key]![direction] = value.createTicker();
            }
        )
    );
    _animationTickers = newTickers;
  }
  
  double direction = 0;
  GameTexture? get animation {
    print("got animation in direction $direction!");
    return textureBatch?[current ?? "idle"]?[direction];
  }
  GameSpriteAnimationTicker? get animationTicker => _animationTickers?[current]?[direction];

  /// Returns the current group state.
  String? get current => _current;

  /// The group state to given state.
  ///
  /// Will update [size] if [autoResize] is true.
  set current(String? value) {
    assert(textureBatch != null, 'Texture batch must not be null!');
    assert(
    textureBatch!.containsTexture(value ?? ""),
    'Animation not found for key: $value',
    );

    final changed = value != current;
    _current = value;
    _resizeToSprite();

    if (changed) {
      if (autoResetTicker) {
        animationTicker?.reset();
      }
      _currentAnimationNotifier?.value = value;
    }
  }

  /// Returns the map of animation state and their corresponding animations.
  ///
  /// If you want to change the contents of the map use the animations setter
  /// and pass in a new map of animations.
  Map<String, Map<double?, GameTexture>>? get animations => textureBatch?.textures;
  
  /// Sets the given [value] as new animation state map.
  set animations(Map<String, Map<double?, GameTexture>>? value) {
    if (textureBatch?.textures != value && value != null) {
      if(textureBatch == null) {
        textureBatch = GameTextureBatch(name, value);
      } else {
        textureBatch!.textures = value;
      }

      updateAnimationTickers();
      
      _resizeToSprite();
    }
  }
  
  /// Returns a map containing [SpriteAnimationTicker] for each state.
  Map<String, Map<double?, GameSpriteAnimationTicker>>? get animationTickers => _animationTickers;
  
  /// Returns current value of auto resize flag.
  bool get autoResize => _autoResize;
  
  /// Sets the given value of autoResize flag.
  ///
  /// Will update the [size] to fit srcSize of current animation sprite if set
  /// to  true.
  set autoResize(bool value) {
    _autoResize = value;
    _resizeToSprite();
  }
  
  /// This flag helps in detecting if the size modification is done by
  /// some external call vs [_autoResize]ing code from [_resizeToSprite].
  bool _isAutoResizing = false;

  @mustCallSuper
  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas, normalCanvas, getNormalPaint);
    if(animationTicker == null) {
      return;
    }
    
    canvas.save();
    normalCanvas?.save();

    canvas.translate(-animationTicker!.getSprite().srcSize.x / 2, -animationTicker!.getSprite().srcSize.y + (tilesize.z*0.75));
    normalCanvas?.translate(-animationTicker!.getSprite().srcSize.x / 2, -animationTicker!.getSprite().srcSize.y + (tilesize.z*0.75));
    
    final Vector2 albedoPosition = animationTicker!.currentFrame.srcPosition; 
    
    animationTicker!.getSprite().render(
      canvas,
      normalCanvas!,
      albedoPositionSrc: albedoPosition,
      depthPositionSrc: albedoPosition,
      depthPosition: toWorldPos(position),
      overridePaintDepth: getNormalPaint!()
    );
    
    canvas.restore();
    normalCanvas.restore();
  }

  @mustCallSuper
  @override
  void update(double dt) {
    if (playing) {
      animationTicker?.update(dt);
      _resizeToSprite();
    }
    if ((removeOnFinish[current] ?? false) &&
        (animationTicker?.done() ?? false)) {
      removeFromParent();
    }
    super.update(dt);
  }

  /// Updates the size to current animation sprite's srcSize if
  /// [autoResize] is true.
  void _resizeToSprite() {
    if (_autoResize) {
      _isAutoResizing = true;

      // final newX = animationTicker?.getSprite().srcSize.x ?? 0;
      // final newY = animationTicker?.getSprite().srcSize.y ?? 0;
      //
      // // Modify only if changed.
      // if (size.x != newX || size.y != newY) {
      //   size.setValues(newX / tilesize.x, newY / tilesize.y, 1); //todo check z
      // }

      _isAutoResizing = false;
    }
  }

  /// Turns off [_autoResize]ing if a size modification is done by user.
  void _handleAutoResizeState() {
    if (_autoResize && (!_isAutoResizing)) {
      _autoResize = false;
    }
  }

  @override
  int get hashCode => Object.hashAll([
    super.hashCode,
    removeOnFinish,
    textureBatch,
    playing,
    _autoResize,
    autoResetTicker,
    animationTicker?.currentFrame,
  ]);
  
  Future<void> playAnimation(String name){
    current = name;
    return animationTicker!.completed;
  }
}

extension on NotifyingVector3 {
  void addListener(void Function() handleAutoResizeState) {}
}
