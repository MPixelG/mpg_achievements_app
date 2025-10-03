import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/level_components/checkpoint/checkpoint.dart';
import '../models/playerdata.dart';

// A provider that manages the state of the player in the game.
// It extends Notifier to provide a way to notify listeners about changes in the player's state.
//Notifier is a class from the Riverpod package that allows you to create a state management solution. New since Riverpod 2.0 before it was StateNotifier

//The global provider for the player state. Always declared outside of any class or function
// This provider can be accessed from anywhere in the app to get or update the player's state.
final playerProvider = NotifierProvider<PlayerNotifier, PlayerData>(
  PlayerNotifier.new,
);

class PlayerNotifier extends Notifier<PlayerData> {
  @override
  PlayerData build() {
    // Initialize the player data with default values.
    // This method is called when the provider is first created.
    // You can also fetch initial data from a database or API here.
    // For this example, we are just returning a PlayerData object with a default character name
    return PlayerData(
      playerCharacter: 'default',
      lives: 3,
      gotHit: false,
      lastCheckpoint: null,
    );
  }

  void takeHit() {
    if (state.gotHit || state.isRespawning) return;

    final newLives = state.lives - 1;

    if (newLives <= 0) {
      // If already got hit, do nothing
      state = state.copyWith(lives: 0, gotHit: true, isRespawning: true);
    } else {
      state = state.copyWith(lives: newLives, gotHit: true);
    }
  }

  void heal() {
    state = state.copyWith(lives: state.lives + 1, gotHit: false);
  }

  void setCheckpoint(Checkpoint checkpoint) {
    state = state.copyWith(lastCheckpoint: checkpoint);
  }

  void resetHit() {
    state = state.copyWith(gotHit: false);
  }

  void completeRespawn() {
    state = state.copyWith(isRespawning: false, lives: 3);
  }

  void manualRespawn() {
    state = state.copyWith(isRespawning: true, gotHit: false);
  }
}
