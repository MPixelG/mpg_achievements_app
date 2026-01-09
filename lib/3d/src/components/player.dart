import 'package:mpg_achievements_app/3d/src/components/game_character.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';

class Player extends GameCharacter<PlayerData> {
  Player({
    super.children,
    super.priority,
    super.key,
    super.position,
    required super.size,
    super.anchor,
  });

  @override
  PlayerData initState() => PlayerData();
}