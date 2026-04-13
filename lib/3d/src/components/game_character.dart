import 'dart:async';
import 'dart:math';
import 'package:mpg_achievements_app/3d/src/components/entity.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/rectangle_hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/physicsbody.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class GameCharacter<TState> extends Entity<TState>
    implements DialogueCharacter {
  static const double deceleration = 0.001;
  late RectangleHitbox3D hitbox;

  GameCharacter({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    required super.modelPath,
    super.name,

  });

  @override
  void tickClient(double dt) {
    position += velocity;
    velocity *= pow(deceleration, dt).toDouble();
    super.tickClient(dt);
  }

  @override
  Future<void> onLoad() async {

    hitbox = RectangleHitbox3D(size: size);
    add(hitbox);
    print("Hitbox");
    print(hitbox.id);
    print(hitbox.size);
    hitbox.enableDebugVisual(thermion!);
    await super.onLoad();
    await asset.addAnimationComponent();
    print("addAnimationComponent called on entity: ${asset.entity}");
  }

  @override
  Future<void> onMount() async {
    // register Thermion-ID (int) -> Entity
    PixelAdventure3D.currentInstance.registerEntity(asset.entity, this);
    print("Registered Entity $name with ID ${asset.entity}");
    return super.onMount();
  }

  @override
  String? get characterName => name;

  @override
  Vector3 get worldPosition => position;
}
