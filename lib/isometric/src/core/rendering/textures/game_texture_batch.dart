import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/isometric/src/components/animation/game_sprite_animation_ticker.dart';

import 'game_texture.dart';

class GameTextureBatch { //todo caching
  final Map<String, Map<double?, GameTexture>> _textures = {};
  late String name;

  GameTextureBatch._loadLater();
  bool ready = false;
  Future<void> _loadFromFile(String filePath) async {
    final Map<String, dynamic> metadata = await Flame.assets
        .readJson(filePath);
    
    name = metadata['name'] ?? "UnnamedTextureBatch";
    final Vector2 size = Vector2(metadata['width'].toDouble()??32, metadata['height'].toDouble()??32); 
    
    assert(metadata['textures'] is List<dynamic>,
    "Texture batch metadata must contain a valid 'textures' field!");
    
    final List<Map<String, dynamic>> textures = (metadata['textures'] as List<dynamic>).map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();

    final String path = metadata['path'];
    final String depthPath = metadata['depthMapPath'] ?? "${path.replaceAll(".png", "")}_depth.png";
    
    for (final texture in textures) {
      final String textureName = texture['name'] ?? "unnamed Texture";
      final String customPath = texture['path'] ?? path;
      final String customDepthPath = texture['depthMapPath'] ?? depthPath;
      
      final List<int> positionList = (texture['position'] as List<dynamic>?)?.map<int>((e) => e as int).toList() ?? [0, 0];
      final Vector2 position = Vector2(positionList[0].toDouble(), positionList[1].toDouble());
      
      final double? rotation = texture['rotation'].toDouble();
      final Map<String, dynamic>? animationOptions = texture['animation'];
      
      final int frameCount = animationOptions?['frames'] ?? 1;
      final List<GameSpriteAnimationFrame> frames = [];
      final AnimationDirection direction = _parseAnimationDirection(animationOptions?['direction']) ?? AnimationDirection.horizontal;
      final Vector2 dirVec = _directionToVector(direction)..multiply(size);
      double currentStepTime = 0;
      for (double i = 0; i < frameCount; i++) {
        frames.add(GameSpriteAnimationFrame(position + dirVec*i, currentStepTime));
        currentStepTime += animationOptions?['stepTime']?.toDouble() ?? 0.05;
      }
      
      
      final Image spritesheet = Flame.images.containsKey(customPath) ? await Flame.images.load(customPath) : Flame.images.fromCache(customPath);
      final Image depthSpritesheet = Flame.images.containsKey(customDepthPath) ? Flame.images.fromCache(customDepthPath) : await Flame.images.load(customDepthPath);
      
      _textures[textureName] ??= {};
      _textures[textureName]![rotation] = GameTexture(spritesheet, depthSpritesheet, textureName, rotation, position, size, animationType: _parseAnimationType(animationOptions?['type']!), frames: frames);
    }
    
    
    ready = true;
  }
  
  
  GameTextureBatch(this.name, Map<String, Map<double?, GameTexture>> data){
    _textures.addAll(data);
  }
  
  void dispose(){
    for (var texture in _textures.values) {
      for (var element in texture.values) {
        element.dispose();
      }
    }
  }
  
  
  bool containsTexture(String id) => _textures.containsKey(id);
  
  Map<String, Map<double?, GameTexture>> get textures => _textures;
  set textures(Map<String, Map<double?, GameTexture>> newTextures) => _textures..clear()..addAll(newTextures);


  Map<double?, GameTexture>? operator [](String textureId) => _textures[textureId];
  
  @override
  String toString() => "$name: ${textures.toString()}";
}


Future<GameTextureBatch> loadTextureBatchFromFile(String file) async{
  final GameTextureBatch textureBatch = GameTextureBatch._loadLater();
  await textureBatch._loadFromFile(file);
  return textureBatch;
}

AnimationDirection? _parseAnimationDirection(String str) => switch(str) {
    "horizontal" => AnimationDirection.horizontal,
    "vertical" => AnimationDirection.vertical,
    _ => null
  };

Vector2 _directionToVector(AnimationDirection dir) => (dir == AnimationDirection.horizontal) ? Vector2(1, 0) : Vector2(0, 1);


AnimationType? _parseAnimationType(String str) => switch(str) {
  "loop" => AnimationType.loop,
  "once" => AnimationType.once,
  "pingPong" => AnimationType.pingPong,
  _ => null
};