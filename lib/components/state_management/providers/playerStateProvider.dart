import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpg_achievements_app/components/state_management/models/playerdata.dart';



// A provider that manages the state of the player in the game.
// It extends Notifier to provide a way to notify listeners about changes in the player's state.
//Notifier is a class from the Riverpod package that allows you to create a state management solution. New since Riverpod 2.0 before it was StateNotifier


//The global provider for the player state.
// This provider can be accessed from anywhere in the app to get or update the player's state.
final playerProvider = NotifierProvider<PlayerStateProvider, PlayerData>((){return PlayerStateProvider();});

class PlayerStateProvider extends Notifier<PlayerData> {

@override
  PlayerData build() {
  // Initialize the player data with default values.
  // This method is called when the provider is first created.
  // You can also fetch initial data from a database or API here.
  // For this example, we are just returning a PlayerData object with a default character name
    return PlayerData(playerCharacter: 'name');
  }

  void takeHit(){
    // This method can be used to update the player's state when they take a hit.
    // For example, you might want to decrease the player's health or change their status.

  }

}