import 'package:mpg_achievements_app/3d/src/components/entity.dart'; // Deine Entity Klasse
import 'package:vector_math/vector_math_64.dart';

// every entity is built with this fuction definition
typedef EntityBuilder = Entity Function(Vector3 position, Vector3 size, String name, Map<String, dynamic> properties);

class EntityFactory {

  //here the blueprint for every entity is stored: Name of Entityname -> Function
  static final Map<String, EntityBuilder> _builders = {};

  // regirsters a new type, registration happens in game class onMount
  static void register(String type, EntityBuilder builder) {
    _builders[type] = builder;
  }

  // creates an entity according to type and constructor plan which was stored in the game class, these blueprint are stored in the _builders-map
  //with the register method
  static Entity? create(String type, Vector3 position, Vector3 size, String name, Map<String, dynamic> properties) {
    final builder = _builders[type];

    if (builder == null) {
      print("Type unknown");
      return null;
    }

    return builder(position, size, name, properties);
  }

  static void clear() {
    _builders.clear();
  }
}