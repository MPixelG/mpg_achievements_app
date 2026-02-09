import 'dart:ui';

import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart';

var uuid = const Uuid();

class GameData {
  final String? id;
  final Size size;

  GameData({
    // If an ID is not provided, generate a unique one using the Uuid package. It is made optional here because we do not
    //necessarily need to provide an ID when creating a new PlayerData instance. And if we load a Player from a save file, we can use the ID from that file.
    String? id,
    required this.size,
  }) : id = id ?? uuid.v4(); // Generate a unique ID if not provided;


  GameData copyWith({
    String? id, // ID is optional here, as it should not change after creation
    required Size? size,
   }) => GameData(
    id: id ?? this.id,
    // ID should not change, so we keep the current one if not provided
    size: size ?? this.size,
  );
}