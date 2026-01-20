import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class NpcData {
  final String id;
  final String? npcCharacter;
  final bool isRespawning;

  NpcData({
    // If an ID is not provided, generate a unique one using the Uuid package. It is made optional here because we do not
    //necessarily need to provide an ID when creating a new PlayerData instance. And if we load a Player from a save file, we can use the ID from that file.
    String? id,
    this.npcCharacter,
    this.isRespawning = false,
    }) : id = id ?? uuid.v4(); // Generate a unique ID if not provided;

  //The copyWith method allows you to create a new instance of PlayerData with some properties modified
  //while keeping the others unchanged. This is useful for immutability and state management.
  //It returns a new PlayerData object with the specified properties updated, or the current value if
  //no new value is provided for a property.
  NpcData copyWith({
    String? id, // ID is optional here, as it should not change after creation
    String? npcCharacter,
    bool? isRespawning,
    })
    => NpcData(
    id: id ?? this.id,// ID should not change, so we keep the current one if not provided
    npcCharacter: npcCharacter ?? this.npcCharacter,
    isRespawning: isRespawning ?? this.isRespawning,
    );
}
