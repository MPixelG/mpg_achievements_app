import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
import 'package:mpg_achievements_app/components/level/rendering/tileset_utils.dart';

import '../../../mpg_pixel_adventure.dart';
import 'game_sprite.dart';

class Chunk {
  final int x;
  final int y;
  final int z;

  int zHeightUsedPixels = 0;

  final List<ChunkTile> _tiles = [];

  Image? albedoMap;
  Image? normalAndDepthMap;


  Chunk(this.x, this.y, this.z);

  Chunk.fromGameTileMap(GameTileMap gameTileMap, this.x, this.y, this.z){
    final map = gameTileMap.tiledMap;
    void registerTile(int gid, int x, int y, int z) async{
      final chunkX = x ~/ chunkSize;
      final chunkY = y ~/ chunkSize;
      if (chunkX == this.x && chunkY == this.y) {
        _tiles.add(ChunkTile(gid, x % Chunk.chunkSize, y % Chunk.chunkSize, z % Chunk.chunkSize));
        if(zHeightUsedPixels < (z+1) * tilesize.z){
          zHeightUsedPixels = ((z+1) * tilesize.z).toInt();
        }
      }
    }

    int layerIndex = 0;
    knownTilesets.addAll(map.tilesets);
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        if(layerIndex != z) {
          layerIndex++;
          continue; //only load tiles for the specified z layer
        }

        if (layer.chunks!.isNotEmpty) {
          for (final chunk in layer.chunks!) {
            final chunkData = chunk.data;
            final chunkWidth = chunk.width;
            final offsetX = chunk.x;
            final offsetY = chunk.y;
            for (int i = 0; i < chunkData.length; i++) { //all the chunk tiles
              final gid = chunkData[i]; //get the gid
              if (gid == 0) continue; //if its 0, it means its empty
              final x = (i % chunkWidth) + offsetX; //calculate the x and y position of the tile in the map
              final y = (i ~/ chunkWidth) + offsetY;
              registerTile(gid, x, y, layerIndex);
            }
          }
        } else { //if the world is not infinite
          final data = layer.data; //we get the data
          final width = layer.width;//the width of the layer
          for (int i = 0; i < data!.length; i++) { //iterate through all tiles
            final gid = data[i]; //get the gid
            if (gid == 0) continue; //if its 0, it means its empty
            final x = i % width; //calculate the x and y position of the tile in the map
            final y = i ~/ width;
            registerTile(gid, x, y, layerIndex);
          }
        }

        layerIndex += 1; //increase the layer index for the next layer
      }
    }
    totalZLayers = layerIndex;

    reSortTiles();
    Future.delayed(Duration(seconds: 2), () => rebuildMaps([]));
  }

  void reSortTiles(){
    _tiles.sort((a, b) {
      Vector2 pos1 = a.pos;
      Vector2 pos2 = b.pos;

      int comparedPos = pos1.compareTo(pos2); //compare the foot y positions

      if (comparedPos != 0) {
        return comparedPos;
      }

      return 0;
    });
  }


  Future<void> rebuildMaps(Iterable<IsometricRenderable> additionals) async{
    await Future.wait([
      buildAlbedoMap(),
      buildNormalAndDepthMap()
    ]);
  }

  Future<void> buildAlbedoMap() async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (final tile in _tiles) { //render everything in the sorted order
      Vector2 renderPos = toWorldPos(tile.pos, layerIndex: tile.chunkZ.toDouble());
      tile._sprite!.albedo.render(canvas, position: renderPos);
    }

    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(((Chunk.chunkSize) * tilesize.x).toInt(), ((Chunk.chunkSize) * tilesize.y).toInt());
  }

  Vector2 toWorldPos(Vector2 gridPos, {double layerIndex = 0}) {
    final localPoint = Vector2(
      (gridPos.x - gridPos.y + (chunkSize)) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position

    //apply vertical movement for different layers according to z-index
    final layerOffset = Vector2(0, layerIndex * tilesize.z/32);//works for now as each tile is 32 pixels high in the tileset
    return localPoint + layerOffset;
  }

  Future<void> buildNormalAndDepthMap() async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);


    for (final tile in _tiles) { //render everything in the sorted order
      Vector2 renderPos = toWorldPos(tile.pos, layerIndex: tile.chunkZ.toDouble());
      tile._sprite!.normalAndDepth!.render(canvas, position: renderPos);
    }

    final picture = recorder.endRecording();
    normalAndDepthMap = await picture.toImage(((Chunk.chunkSize+1) * tilesize.x).toInt(), ((Chunk.chunkSize+1) * tilesize.y).toInt());
  }


  Paint paint = Paint();
  void render(Canvas canvas, Iterable<IsometricRenderable> components, [Offset offset = Offset.zero]) {
    if(albedoMap != null){
      canvas.drawImage(albedoMap!, offset, paint);
      canvas.drawCircle(offset, 5, Paint()..color = Colors.red);
    } else {
    }
  }


  static Set<Tileset> knownTilesets = {};
  static const int chunkSize = 16; // Size of each chunk in tiles
  static int totalZLayers = 1;
}

class ChunkTile {
  final int gid;
  final int x;
  final int y;

  final int chunkZ;

  Vector2 get pos => Vector2(x.toDouble(), y.toDouble());

  ChunkTile(this.gid, this.x, this.y, this.chunkZ) {
    Future.microtask(_loadSprite);
  }

  GameSprite? _sprite;

  bool loadingSprite = false;

  Future<void> _loadSprite() async {
    if(loadingSprite) return;
    _sprite ??= await getTextureOfGid(gid);

    loadingSprite = false;
  }
}

Map<int, GameSprite> textures = {};
Future<GameSprite> getTextureOfGid(int gid) async{
  GameSprite? cacheResult = textures[gid];
  if(cacheResult != null) {
    print("getting texture from cache!");

    return cacheResult;
  } print("found nothing for gid $gid");


  Tileset tileset = findTileset(gid, Chunk.knownTilesets);
  Image tilesetImage = (await getImageFromTileset(tileset))!;
  Image normalMapImg = (await getNormalImageFromTileset(tileset))!;
  print("got tileset images!");

  final raw = gid & 0x1FFFFFFF;
  //calculate the local index of the tile within its tileset
  final localIndex = raw - tileset.firstGid!;

  final cols = tileset.columns!; //amount of columns in the tileset image
  final row = localIndex ~/ cols; //calculate the row and column of the tile in the tileset image
  final col = localIndex % cols; //same for column
  final srcSize = tilesize.xy; //the size of the tile in the tileset image

  final sprite = Sprite( //get the sprite for the tile
    tilesetImage, //the tileset
    srcPosition: Vector2(col * tilesize.x, row * tilesize.y), //the position of the tile in the tileset image
    srcSize: srcSize, //and its size
  );
  final normalSprite = Sprite( //get the sprite for the tile
    normalMapImg, //the tileset
    srcPosition: Vector2(col * tilesize.x, row * tilesize.y), //the position of the tile in the tileset image
    srcSize: srcSize, //and its size
  );

  print("got image from tileset!");

  GameSprite gameSprite = GameSprite(sprite, normalSprite);
  textures[gid] = gameSprite;
  print("done! gid: $gid");

  return gameSprite;
}

extension on Vector2 {
  int compareTo(Vector2 gridPos) {
    return (distanceTo(Vector2.zero()).compareTo(gridPos.distanceTo(Vector2.zero())));
  }
}