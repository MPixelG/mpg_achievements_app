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
import 'package:mpg_achievements_app/components/util/isometric_utils.dart';

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
    worldSize = Vector2(
      gameTileMap.tiledMap.width.toDouble() * tilesize.x,
      gameTileMap.tiledMap.height.toDouble() * tilesize.z,
    );
    final map = gameTileMap.tiledMap;
    void registerTile(int gid, int x, int y, int z) {

      x += z;
      y += z;

      final chunkX = x ~/ chunkSize;
      final chunkY = y ~/ chunkSize;

      if (chunkX == this.x && chunkY == this.y) {
        final localX = x - chunkX * chunkSize;
        final localY = y - chunkY * chunkSize;

        _tiles.add(ChunkTile(gid, localX, localY, x, y, z, 0));


        int topPos = ((z) * tilesize.z).toInt();
        if (gid != 0 && topPos > zHeightUsedPixels) {
          print("new top pos in chunk ${this.x}, ${this.y}: $topPos");
          zHeightUsedPixels = topPos;
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

    _tiles.forEach((element) => element.zAdjustPos = zHeightUsedPixels);

    reSortTiles([]);
    Future.delayed(Duration(seconds: 1), () => rebuildMaps([]));
  }

  static Vector2 worldSize = Vector2.zero();

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
    canvas.save();
    Vector2 worldPos = toWorldPos(Vector3((x-1) * chunkSize.toDouble(), y * chunkSize.toDouble(), 0)) + Vector2(0, (tilesize.z * chunkSize / 2) - zHeightUsedPixels);

    Vector2 bottomLeftPos = Vector2(Chunk.chunkSize * tilesize.x, (Chunk.chunkSize + 1) * tilesize.z + zHeightUsedPixels);

    //if(additionals.isNotEmpty) canvas.drawRect(Offset.zero & Size(bottomLeftPos.x, bottomLeftPos.y), Paint()..color = Color(hashCode).withValues(alpha: 0.5));

    canvas.translate(-worldPos.x, -worldPos.y);

    for (final tile in allRenderables) {
      tile.renderAlbedo(canvas);
    }
    canvas.restore();


    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(bottomLeftPos.x.toInt(), bottomLeftPos.y.toInt());
  }

  Future<void> buildNormalAndDepthMap(Iterable<IsometricRenderable> additionals) async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();
    print("current maxz: $zHeightUsedPixels");
    Vector2 worldPos = toWorldPos(Vector3((x -1) * chunkSize.toDouble(), y * chunkSize.toDouble(), 0));
    if(additionals.isNotEmpty) canvas.drawRect(Offset.zero & Size(((Chunk.chunkSize) * tilesize.x), ((Chunk.chunkSize) * tilesize.z)), Paint()..color = Color(hashCode).withValues(alpha: 0.5));
    canvas.translate(-worldPos.x, -worldPos.y);

    for (final tile in allRenderables) {
      if(tile.renderNormal == null) continue;
      final double startVal = ((tile.gridFeetPos.z - 1) / (zHeightUsedPixels)) * 255;
      final double endVal = (tile.gridFeetPos.z / zHeightUsedPixels);
      tile.renderNormal!(canvas, Paint()..colorFilter = ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, endVal, 0, startVal,
        0, 0, 0, 1, 0,
      ]));
    }
    canvas.restore();


    final picture = recorder.endRecording();
    normalAndDepthMap = await picture.toImage(((Chunk.chunkSize) * tilesize.x).toInt(), ((Chunk.chunkSize) * tilesize.z).toInt());
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
  int zAdjustPos;

  Vector3 get posWorld => Vector3(worldX.toDouble(), worldY.toDouble(), z.toDouble());
  Vector3 get posLocal => Vector3(localX.toDouble(), localY.toDouble(), z.toDouble());

  ChunkTile(this.gid, this.localX, this.localY, this.worldX, this.worldY, this.z, this.zAdjustPos) {
    print("$gid at $worldX, $worldY, $z");
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
  void Function(Canvas canvas) get renderAlbedo {
    return (Canvas canvas) {
      Vector2 position = toWorldPos(posWorld) - Vector2(tilesize.x / 2, 0);
      _sprite!.albedo.render(canvas, position: position);
    };
  }

  @override
  void Function(Canvas canvas, Paint? overridePaint)? get renderNormal {
    if(_sprite == null || _sprite!.normalAndDepth == null) return null;
    return (Canvas canvas, Paint? overridePaint) {
      Vector2 position = toWorldPos(posWorld) - Vector2(tilesize.x / 2, 0);
      _sprite!.normalAndDepth!.render(canvas, position: position, overridePaint: overridePaint);
    };
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