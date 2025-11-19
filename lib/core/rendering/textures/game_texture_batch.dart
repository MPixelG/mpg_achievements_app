import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/core/rendering/textures/game_texture.dart';

class GameTextureBatch {
  final Map<String, GameTexture> _textures = {};
  late String name;

  GameTextureBatch();
  GameTextureBatch.fromFile(String filePath) {
    loadFromFile(filePath);
  }

  bool ready = false;
  void loadFromFile(String filePath) async {
    final Map<String, dynamic> metadata = await Flame.assets
        .readJson(filePath);

    assert(metadata['textures'] is Iterable,
        "Texture batch metadata must contain a 'textures' field!");

    for (var textureData in metadata['textures']) {
      final GameTexture texture = GameTexture.fromMetadata(
          textureData, metadata['basePath']);
      _textures[texture.name] = texture;
    }

    name = metadata['name'] ?? "UnnamedTextureBatch";
    ready = true;
  }

}