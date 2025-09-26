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

  NeighborChunkCluster? neighborChunkCluster;
  bool usesTempNeighborTileRendering = false;
  bool isUsedByNeighbor = false;

  int zHeightUsedPixels = 0;

  final List<ChunkTile> tiles = [];

  Image? albedoMap;
  Image? normalAndDepthMap;


  Chunk(this.x, this.y, this.z, [this.neighborChunkCluster]);


  Chunk.fromGameTileMap(GameTileMap gameTileMap, this.x, this.y, this.z, [this.neighborChunkCluster]){
    neighborChunkCluster ??= NeighborChunkCluster();
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

        tiles.add(ChunkTile(gid, localX, localY, x, y, z, 0));


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

    tiles.forEach((element) => element.zAdjustPos = zHeightUsedPixels);

    reSortTiles([]);
    Future.delayed(Duration(seconds: 1), () => rebuildMaps([]));
  }

  static Vector2 worldSize = Vector2.zero();

  List<IsometricRenderable> allRenderables = [];
  void reSortTiles(Iterable<IsometricRenderable> additionals, {Iterable<IsometricRenderable>? neighborChunkTiles}){
    allRenderables.clear();

    allRenderables.addAll(tiles);
    allRenderables.addAll(additionals);

    if(neighborChunkTiles != null) {
      allRenderables.addAll(neighborChunkTiles);
    }

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

    Iterable<IsometricRenderable> containedAdditionals = additionals.toList().where((element) => containsRenderable(element));

    if(neighborChunkCluster != null) {
      usesTempNeighborTileRendering = true;

      List<IsometricRenderable> neighborChunkTiles = [];
      List<Chunk> neighborChunks = [];

      for (var value in additionals) {
        neighborChunks.addAll(neighborChunkCluster!.getWhereContained(value));
      }

      for (var element in neighborChunks) {
        neighborChunkTiles.addAll(element.tiles);
      }

      reSortTiles(containedAdditionals, neighborChunkTiles: neighborChunkTiles);
    } else{
      usesTempNeighborTileRendering = false;
      reSortTiles(containedAdditionals);
    }

    await Future.wait([
      buildAlbedoMap(containedAdditionals),
      buildNormalAndDepthMap(containedAdditionals)
    ]);
  }

  Vector2 getStartRenderPos([int? correctedX, int? correctedY]){
    return toWorldPos(Vector3(((correctedX ?? x)-1) * chunkSize.toDouble(), (correctedY??y) * chunkSize.toDouble(), 0)) + Vector2(0, (tilesize.z * chunkSize / 2) - zHeightUsedPixels);
  }

  void adjustRenderingBounds(Vector2 gridPos, Vector2 bottomRightPos, Iterable<IsometricRenderable> additionals){
    bool l = false;
    bool r = false;
    bool t = false;
    bool b = false;

    for(final element in additionals) {
      if(!(b&&r) && (neighborChunkCluster?.bottomRight?.containsRenderable(element) ?? false)) {
        b = true;
        r = true;
      }
      if(!(b&&l) && (neighborChunkCluster?.bottomLeft?.containsRenderable(element) ?? false)) {
        b = true;
        l = true;
      }
      if(!(t&&r) && (neighborChunkCluster?.topRight?.containsRenderable(element) ?? false)) {
        t = true;
        r = true;
      }
      if(!(t&&l) && (neighborChunkCluster?.topLeft?.containsRenderable(element) ?? false)) {
        t = true;
        l = true;
      }
      if(!t && (neighborChunkCluster?.top?.containsRenderable(element) ?? false)) t = true;
      if(!b && (neighborChunkCluster?.bottom?.containsRenderable(element) ?? false)) b = true;
      if(!r && (neighborChunkCluster?.right?.containsRenderable(element) ?? false)) r = true;
      if(!l && (neighborChunkCluster?.left?.containsRenderable(element) ?? false)) l = true;
    }

    if (l) {
      gridPos.x--;
    }
    if(t) {
      gridPos.y--;
    }

    if (r) {
      bottomRightPos.x *= 2;
    }
    if(b) {
      bottomRightPos.y *= 2;
    }

  }

  Future<void> buildAlbedoMap(Iterable<IsometricRenderable> additionals) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();

    Vector2 adjustedGridPos = Vector2(x.toDouble(), y.toDouble());
    Vector2 bottomRightPos = Vector2(Chunk.chunkSize * tilesize.x, (Chunk.chunkSize + 1) * tilesize.z + zHeightUsedPixels);
    adjustRenderingBounds(adjustedGridPos, bottomRightPos, additionals);


    Vector2 worldPos = getStartRenderPos(adjustedGridPos.x.toInt(), adjustedGridPos.y.toInt());


    if(usesTempNeighborTileRendering) canvas.drawRect(Offset.zero & Size(bottomRightPos.x, bottomRightPos.y), Paint()..color = Color(hashCode).withValues(alpha: 0.5));

    canvas.translate(-worldPos.x, -worldPos.y);

    for (final tile in allRenderables) {
      tile.renderAlbedo(canvas);
    }
    canvas.restore();


    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(bottomRightPos.x.toInt(), bottomRightPos.y.toInt());
  }

  Future<void> buildNormalAndDepthMap(Iterable<IsometricRenderable> additionals) async{
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();
    print("current maxz: $zHeightUsedPixels");
    Vector2 worldPos = getStartRenderPos();
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

  bool containsRenderable(IsometricRenderable renderable){
    double xPos = x * chunkSize.toDouble();
    double yPos = y * chunkSize.toDouble();
    double xPosEnd = (x + 1) * chunkSize.toDouble();
    double yPosEnd = (y + 1) * chunkSize.toDouble();

    return (renderable.gridHeadPos.x >= xPos && renderable.gridFeetPos.x < xPosEnd &&
        renderable.gridHeadPos.y >= yPos && renderable.gridFeetPos.y < yPosEnd);
  }


  Paint paint = Paint();
  Set<IsometricRenderable> currentAdditionalComponents = {};
  void render(Canvas canvas, Iterable<IsometricRenderable> components, NeighborChunkCluster neighborChunkCluster, [Offset offset = Offset.zero]) {
    if(isUsedByNeighbor) return;
    this.neighborChunkCluster = neighborChunkCluster;


    Set<IsometricRenderable> newComponents = {};


    components.where((element) => element.dirty).forEach((element) {
      if(containsRenderable(element)){
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

class NeighborChunkCluster{
  Chunk? top;
  Chunk? right;
  Chunk? left;
  Chunk? bottom;
  Chunk? topRight;
  Chunk? topLeft;
  Chunk? bottomRight;
  Chunk? bottomLeft;
  NeighborChunkCluster({this.top, this.right, this.left, this.bottom, this.topLeft, this.topRight, this.bottomLeft, this.bottomRight});

  List<Chunk> getWhereContained(IsometricRenderable renderable){
    List<Chunk> out = [];

    if(top != null && top!.containsRenderable(renderable)) out.add(top!);
    if(right != null && right!.containsRenderable(renderable)) out.add(right!);
    if(left != null && left!.containsRenderable(renderable)) out.add(left!);
    if(bottom != null && bottom!.containsRenderable(renderable)) out.add(bottom!);
    if(topRight != null && topRight!.containsRenderable(renderable)) out.add(topRight!);
    if(topLeft != null && topLeft!.containsRenderable(renderable)) out.add(topLeft!);
    if(bottomRight != null && bottomRight!.containsRenderable(renderable)) out.add(bottomRight!);
    if(bottomLeft != null && bottomLeft!.containsRenderable(renderable)) out.add(bottomLeft!);

    return out;
  }
}