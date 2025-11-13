import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/cupertino.dart' hide Image;
import 'package:mpg_achievements_app/components/level_components/entity/game_character.dart';
import 'package:mpg_achievements_app/core/math/iso_anchor.dart';

abstract class AnimatedCharacter<T> extends GameCharacter with HasPaint{
  /// Key with the current playing animation
  T? _current;

  ValueNotifier<T?>? _currentAnimationNotifier;

  /// A [ValueNotifier] that notifies when the current animation changes.
  ValueNotifier<T?> get currentAnimationNotifier =>
      _currentAnimationNotifier ??= ValueNotifier<T?>(_current);

  /// Map with the mapping each state to the flag removeOnFinish
  final Map<T, bool> removeOnFinish;

  /// Map with the available states for this animation group
  Map<T, SpriteAnimation>? _animations;

  /// Map containing animation tickers for each animation state.
  Map<T, SpriteAnimationTicker>? _animationTickers;

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
    Map<T, SpriteAnimation>? animations,
    T? current,
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
        _animations = animations,
        _autoResize = autoResize ?? true,
        _animationTickers = animations != null
            ? Map.fromEntries(
          animations.entries
              .map((e) => MapEntry(e.key, e.value.createTicker()))
              .toList(),
        )
            : null {
    if (paint != null) {
      this.paint = paint;
    }

    /// Register a listener to differentiate between size modification done by
    /// external calls v/s the ones done by [_resizeToSprite].
    size.addListener(_handleAutoResizeState);
    _resizeToSprite();
  }

  /// Creates a SpriteAnimationGroupComponent from a [size], an [image] and
  /// [data].
  /// Check [SpriteAnimationData] for more info on the available options.
  ///
  /// Optionally [removeOnFinish] can be mapped to true to have this component
  /// be auto removed from the FlameGame when the animation is finished.
  AnimatedCharacter.fromFrameData(
      Image image,
      Map<T, SpriteAnimationData> data, {
        T? current,
        bool? autoResize,
        bool playing = true,
        Map<T, bool> removeOnFinish = const {},
        bool autoResetTicker = true,
        Paint? paint,
        Vector3? position,
        required Vector3 size,
        Vector3? scale,
        double? angle,
        double nativeAngle = 0,
        Anchor3D? anchor,
        int? priority,
        ComponentKey? key,
      }) : this(
    animations: data.map((key, value) => MapEntry(
        key,
        SpriteAnimation.fromFrameData(
          image,
          value,
        ),
      )),
    current: current,
    autoResize: autoResize,
    removeOnFinish: removeOnFinish,
    autoResetTicker: autoResetTicker,
    playing: playing,
    paint: paint,
    position: position,
    size: size,
    scale: scale,
    anchor: anchor,
    priority: priority,
    key: key,
  );

  SpriteAnimation? get animation => _animations?[current];
  SpriteAnimationTicker? get animationTicker => _animationTickers?[current];

  /// Returns the current group state.
  T? get current => _current;

  /// The group state to given state.
  ///
  /// Will update [size] if [autoResize] is true.
  set current(T? value) {
    assert(_animations != null, 'Animations not set');
    assert(
    _animations!.keys.contains(value),
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
  Map<T, SpriteAnimation>? get animations =>
      _animations != null ? Map.unmodifiable(_animations!) : null;

  /// Sets the given [value] as new animation state map.
  set animations(Map<T, SpriteAnimation>? value) {
    if (_animations != value) {
      _animations = value;

      _animationTickers = _animations != null
          ? Map.fromEntries(
        _animations!.entries
            .map((e) => MapEntry(e.key, e.value.createTicker()))
            .toList(),
      )
          : null;
      _resizeToSprite();
    }
  }

  /// Returns a map containing [SpriteAnimationTicker] for each state.
  Map<T, SpriteAnimationTicker>? get animationTickers => _animationTickers;

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
    if(animationTicker == null) return;

    canvas.save();
    canvas.translate(-animationTicker!.getSprite().srcSize.x / 2, -animationTicker!.getSprite().srcSize.y);
    animationTicker!.getSprite().render(
      canvas,
      overridePaint: paint,
    );
    canvas.restore();
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
}