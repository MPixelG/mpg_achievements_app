import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:mpg_achievements_app/components/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometric_tiled_component.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_tile_map.dart';
import 'package:mpg_achievements_app/components/level/rendering/tileset_utils.dart';

import '../../../mpg_pixel_adventure.dart';
import 'game_sprite.dart';

class Chunk {
  final int x;
  final int y;
  final int z;

  double zHeightUsedPixels = 0;

  final List<ChunkTile> _tiles = [];

  Image? albedoMap;
  Image? normalAndDepthMap;


  Chunk(this.x, this.y, this.z);

  static int currentMaxZHeight = 0;

  Chunk.fromGameTileMap(GameTileMap gameTileMap, this.x, this.y, this.z){
    final map = gameTileMap.tiledMap;
    void registerTile(int gid, int x, int y, int z) {

      if(z > currentMaxZHeight){
        currentMaxZHeight = z;
      }

      final sx = x + z;
      final sy = y + z;

      final chunkX = sx ~/ chunkSize;
      final chunkY = sy ~/ chunkSize;


      if (chunkX == this.x && chunkY == this.y) {
        final localX = sx - chunkX * chunkSize;
        final localY = sy - chunkY * chunkSize;
        _tiles.add(ChunkTile(gid, localX, localY, x, y, z));

        if (gid != 0 && zHeightUsedPixels < (z + 1) * tilesize.z) {
          zHeightUsedPixels = ((z + 1) * tilesize.z);
        }
      }
    }


    int layerIndex = 0;
    knownTilesets.addAll(map.tilesets);
    for (final layer in map.layers) {
      if (layer is TileLayer) {


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

    reSortTiles([]);
    Future.delayed(Duration(seconds: 1), () => rebuildMaps([]));
  }

  List<IsometricRenderable> allRenderables = [];
  void reSortTiles(Iterable<IsometricRenderable> additionals){
    allRenderables.clear();
    allRenderables.addAll(_tiles);
    allRenderables.addAll(additionals);

    allRenderables.sort((a, b) {
      Vector3 pos1 = a.gridFeetPos;
      Vector3 pos2 = b.gridFeetPos;

      pos1.z *= tilesize.z;
      pos2.z *= tilesize.z;

      int comparedPos = pos1.compareTo(pos2); //compare the foot y positions

      if (comparedPos != 0) {
        return comparedPos;
      }

      return 0;
    });
  }


  Future<void> rebuildMaps(Iterable<IsometricRenderable> additionals) async{
    reSortTiles(additionals);
    await Future.wait([
      buildAlbedoMap(additionals),
      buildNormalAndDepthMap(additionals)
    ]);
  }

  Future<void> buildAlbedoMap(Iterable<IsometricRenderable> additionals) async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    for (final tile in allRenderables) {
      Vector2 renderPos = toLocalPos(tile.gridFeetPos.xy, layerIndex: tile.gridFeetPos.z.toDouble());
      tile.renderAlbedo(canvas, position: renderPos);

      // if(tile.posLocal == Vector3(2, 2, 0) && additionals.isNotEmpty){
      //   canvas.drawCircle(renderPos.toOffset(), 25, Paint()..color = Colors.red);
      // }

    }

    //canvas.drawRect(Offset.zero & Size(chunkSize * tilesize.x, chunkSize * tilesize.z + zHeightUsedPixels), Paint()..color = Color(hashCode));

    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(((Chunk.chunkSize) * tilesize.x).toInt(), ((Chunk.chunkSize) * tilesize.y).toInt());
  }
  Future<void> buildNormalAndDepthMap(Iterable<IsometricRenderable> additionals) async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);


    for (final tile in _tiles) { //render everything in the sorted order
      Vector2 renderPos = toLocalPos(tile.posWorld.xy, layerIndex: tile.z.toDouble());
      final double startVal = ((tile.z - 1) / currentMaxZHeight) * 255;
      final double endVal = (tile.z / currentMaxZHeight);
      tile._sprite!.normalAndDepth!.render(canvas, position: renderPos, overridePaint: Paint()..colorFilter = ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, endVal, 0, startVal,
          0, 0, 0, 1, 0,
          ]));
    }

    final picture = recorder.endRecording();
    normalAndDepthMap = await picture.toImage(((Chunk.chunkSize+1) * tilesize.x).toInt(), ((Chunk.chunkSize+1) * tilesize.y).toInt());
  }

  Vector2 toWorldPos(Vector2 gridPos, {double layerIndex = 0}) {
    final localPoint = Vector2(
      (gridPos.x - gridPos.y + (chunkSize)) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );
    // Convert local point to global world position, Add the maps's visual origin offset back to the local point
    // to get the correct world position

    //apply vertical movement for different layers according to z-index
    final layerOffset = Vector2(0, zHeightUsedPixels - (layerIndex * tilesize.z / 32)); //works for now as each tile is 32 pixels high in the tileset
    return localPoint + layerOffset;
  }


  Vector2 toLocalPos(Vector2 gridPos, {double layerIndex = 0}) {

    gridPos -= Vector2(x.toDouble() * chunkSize, y.toDouble() * chunkSize);

    final localPoint = Vector2(
      (gridPos.x - gridPos.y + (chunkSize)) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );

    final layerOffset = Vector2(-tilesize.x / 2, zHeightUsedPixels - (0.0 * layerIndex * tilesize.z / 32));

    return localPoint + layerOffset;
  }


  Paint paint = Paint();
  Set<IsometricRenderable> currentAdditionalComponents = {};
  void render(Canvas canvas, Iterable<IsometricRenderable> components, [Offset offset = Offset.zero]) {
    Set<IsometricRenderable> newComponents = {};

    double xPos = x * chunkSize.toDouble();
    double yPos = y * chunkSize.toDouble();
    double xPosEnd = (x + 1) * chunkSize.toDouble();
    double yPosEnd = (y + 1) * chunkSize.toDouble();
    components.where((element) => element.dirty).forEach((element) {
      if(element.gridHeadPos.x >= xPos && element.gridFeetPos.x < xPosEnd &&
         element.gridHeadPos.y >= yPos && element.gridFeetPos.y < yPosEnd){
        newComponents.add(element);
        element.updatesNextFrame = true;
      }
    });

    if(newComponents.isNotEmpty || currentAdditionalComponents.isNotEmpty){
      //print("updating chunk at $x,$y. current has ${currentAdditionalComponents.length} new has ${newComponents.length}");
      currentAdditionalComponents = newComponents;
      rebuildMaps(currentAdditionalComponents);
    }

    if(albedoMap != null){
      canvas.drawImage(albedoMap!, offset, paint);
    } else {
    }
  }


  static Set<Tileset> knownTilesets = {};
  static const int chunkSize = 16; // Size of each chunk in tiles
  static int totalZLayers = 1;
}

class ChunkTile with IsometricRenderable{
  final int gid;
  final int localX;
  final int localY;
  final int worldX;
  final int worldY;
  final int z;

  Vector3 get posWorld => Vector3(worldX.toDouble(), worldY.toDouble(), z.toDouble());
  Vector3 get posLocal => Vector3(localX.toDouble(), localY.toDouble(), z.toDouble());

  ChunkTile(this.gid, this.localX, this.localY, this.worldX, this.worldY, this.z) {
    Future.microtask(_loadSprite);
  }

  GameSprite? _sprite;

  bool loadingSprite = false;

  Future<void> _loadSprite() async {
    if(loadingSprite) return;
    _sprite ??= await getTextureOfGid(gid);

    loadingSprite = false;
  }

  @override
  Vector3 get gridFeetPos => posWorld;

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 1);

  @override
  RenderCategory get renderCategory => RenderCategory.tile;

  @override
  void Function(Canvas canvas, {Vector2 position, Vector2 size})? get renderNormal {
    if(_sprite == null || _sprite!.normalAndDepth == null) return null;
    return (Canvas canvas, {Vector2? position, Vector2? size}) => _sprite!.normalAndDepth!.render(canvas, position: position);
  }

  @override
  void Function(Canvas canvas, {Vector2 position, Vector2 size}) get renderAlbedo {
    return (Canvas canvas, {Vector2? position, Vector2? size}) => _sprite!.albedo.render(canvas, position: position);
  }
}

Map<int, GameSprite> textures = {};
Future<GameSprite> getTextureOfGid(int gid) async{
  GameSprite? cacheResult = textures[gid];
  if(cacheResult != null) {
    return cacheResult;
  }


  Tileset tileset = findTileset(gid, Chunk.knownTilesets);
  Image tilesetImage = (await getImageFromTileset(tileset))!;
  Image normalMapImg = (await getNormalImageFromTileset(tileset))!;

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


  GameSprite gameSprite = GameSprite(sprite, normalSprite);
  textures[gid] = gameSprite;
  return gameSprite;
}

extension VectorComparing on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(Vector3.zero()).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}