import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/3d/src/state_management/models/game_data.dart';


final gameProvider = NotifierProvider<GameNotifier, GameData>(
  GameNotifier.new,);

class GameNotifier extends Notifier<GameData> {

  @override
  GameData build() =>
      // Initialize the player data with default values.
  // This method is called when the provider is first created.
  // You can also fetch initial data from a database or API here.
  // For this example, we are just returning a PlayerData object with a default character name
  GameData(size: const Size(0.0,0.0));

  void updateSize(Size newSize) {
    state = state.copyWith(size: newSize);
  }
}

