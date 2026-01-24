import 'dart:async';
import 'dart:math';

import 'package:mpg_achievements_app/3d/src/components/entity.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/core/dialogue_utils/dialogue_character.dart';
import 'package:vector_math/vector_math_64.dart';

abstract class GameCharacter<TState> extends Entity<TState> implements DialogueCharacter{
  Vector3 velocity = Vector3.zero();
  static const double deceleration = 0.1; 
  
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
  FutureOr<void> onMount() {
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