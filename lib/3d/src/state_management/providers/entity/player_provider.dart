import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/entity/player_data.dart';

class PlayerProvider extends Notifier<PlayerData> {
  @override
  PlayerData build() => PlayerData();
}