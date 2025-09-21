import 'package:uuid/uuid.dart';

import '../../level_components/checkpoint/checkpoint.dart';


var uuid = Uuid();


class PlayerData {

  final String id;
  final String playerCharacter;
  final int lives;
  final bool gotHit;
  final bool isRespawning;
  final Checkpoint? lastCheckpoint;

  PlayerData({
    // If an ID is not provided, generate a unique one using the Uuid package. It is made optional here because we do not
    //necessarily need to provide an ID when creating a new PlayerData instance. And if we load a Player from a save file, we can use the ID from that file.
    String? id,
    required this.playerCharacter,
    this.lives = 3,
    this.gotHit = false,
    this.isRespawning = false,
    this.lastCheckpoint,})
      : id = id ?? uuid.v4(); // Generate a unique ID if not provided;


//The copyWith method allows you to create a new instance of PlayerData with some properties modified
//while keeping the others unchanged. This is useful for immutability and state management.
//It returns a new PlayerData object with the specified properties updated, or the current value if
//no new value is provided for a property.
  PlayerData copyWith({
    String? id, // ID is optional here, as it should not change after creation
    String? playerCharacter,
    int? lives,
    bool? gotHit,
    bool? isRespawning,
    Checkpoint? lastCheckpoint,
  }) {
    return PlayerData(
      id: id ?? this.id,
      // ID should not change, so we keep the current one if not provided
      playerCharacter: playerCharacter ?? this.playerCharacter,
      lives: lives ?? this.lives,
      gotHit: gotHit ?? this.gotHit,
      isRespawning: isRespawning ?? this.isRespawning,
      lastCheckpoint: lastCheckpoint ?? this.lastCheckpoint,
    );
  }
}