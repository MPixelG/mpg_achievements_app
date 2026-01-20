import 'package:mpg_achievements_app/3d/src/components/entity.dart';

abstract class GameCharacter<TState> extends Entity<TState>{
  GameCharacter({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
    super.asset,
    super.modelPath,
  });
}