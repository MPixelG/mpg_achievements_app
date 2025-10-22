import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../../../mpg_pixel_adventure.dart';
import '../../../util/isometric_utils.dart';
import '../isometric/isometric_renderable.dart';
import 'chunk_tile.dart';
import 'game_tile_map.dart';
import 'neighbor_chunk_cluster.dart';

class Chunk {
  final int x;
  final int y;
  final int z;

  NeighborChunkCluster? neighborChunkCluster;
  bool usesTempNeighborTileRendering = false;
  bool isUsedByNeighbor = false;

  Vector2? albedoWorldTopLeft;
  int albedoWidth = 0;
  int albedoHeight = 0;

  int zHeightUsedPixels = 0;
  static int highestZTileInWorld = 0;

  final List<ChunkTile> tiles = [];

  Image? albedoMap;
  Image? normalAndDepthMap;


  static Set<Tileset> knownTilesets = {};
  static const int chunkSize = 16; // Size of each chunk in tiles
  static int totalZLayers = 1;

  Chunk(this.x, this.y, this.z, [this.neighborChunkCluster]);

  Chunk.fromGameTileMap(
    GameTileMap gameTileMap,
    this.x,
    this.y,
    this.z, [
    this.neighborChunkCluster,
  ]) {
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

        int topPos = ((z) * tilesize.z).toInt();
        if (gid != 0 && topPos > zHeightUsedPixels) {
          zHeightUsedPixels = topPos;
        }
        if (z > highestZTileInWorld) {
          highestZTileInWorld = z;
        }

        tiles.add(ChunkTile(gid, localX, localY, x, y, z, 0));
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
            for (int i = 0; i < chunkData.length; i++) {
              //all the chunk tiles
              final gid = chunkData[i]; //get the gid
              if (gid == 0) continue; //if its 0, it means its empty
              final x =
                  (i % chunkWidth) +
                  offsetX; //calculate the x and y position of the tile in the map
              final y = (i ~/ chunkWidth) + offsetY;
              registerTile(gid, x, y, layerIndex);
            }
          }
        } else {
          //if the world is not infinite
          final data = layer.data; //we get the data
          final width = layer.width; //the width of the layer
          for (int i = 0; i < data!.length; i++) {
            //iterate through all tiles
            final gid = data[i]; //get the gid
            if (gid == 0) continue; //if its 0, it means its empty
            final x =
                i %
                width; //calculate the x and y position of the tile in the map
            final y = i ~/ width;
            registerTile(gid, x, y, layerIndex);
          }
        }

        layerIndex += 1; //increase the layer index for the next layer
      }
    }
    totalZLayers = layerIndex;

    for (var element in tiles) {
      element.zAdjustPos = zHeightUsedPixels;
    }

    reSortTiles([]);
    Future.delayed(Duration(seconds: 1), () => rebuildMaps([]));
  }

  static Vector2 worldSize = Vector2.zero();

  List<IsometricRenderable> allRenderables = [];
  void reSortTiles(Iterable<IsometricRenderable> additionals) {
    tiles.sort((a, b) {
      return depth(a).compareTo(depth(b));
    });
  }

  int currentlyActiveOperations = 0;
  static const int maxOperations = 5;
  void rebuildMaps(List<IsometricRenderable> additionals) {
    if(currentlyActiveOperations > maxOperations) return;

    currentlyActiveOperations++;
    List<IsometricRenderable> containedAdditionals = additionals
        .where((element) => containsRenderable(element)).toList();

    if (neighborChunkCluster != null) {
      usesTempNeighborTileRendering = true;

      List<IsometricRenderable> neighborChunkTiles = [];
      List<Chunk> neighborChunks = [];

      for (var value in containedAdditionals) {
        neighborChunks.addAll(neighborChunkCluster!.getWhereContained(value));
      }

      for (var n in neighborChunks) {
        n.isUsedByNeighbor = true;
      }
      usesTempNeighborTileRendering = neighborChunks.isNotEmpty;

      for (var element in neighborChunks) {
        neighborChunkTiles.addAll(element.tiles);
      }

    } else {
      usesTempNeighborTileRendering = false;
    }
    prepareBuildImageMaps();
    buildImageMaps(additionals);
    currentlyActiveOperations--;
  }

  void prepareBuildImageMaps() {
    if (tiles.isEmpty) return;

    int minGridX = 1 << 30, minGridY = 1 << 30;
    int maxGridX = -1 << 30, maxGridY = -1 << 30;
    int maxZ = 0;
    for (final r in tiles) {
      minGridX = math.min(minGridX, r.gridFeetPos.x.toInt());
      minGridY = math.min(minGridY, r.gridFeetPos.y.toInt());
      maxGridX = math.max(maxGridX, r.gridHeadPos.x.toInt());
      maxGridY = math.max(maxGridY, r.gridHeadPos.y.toInt());
      maxZ = math.max(maxZ, r.gridHeadPos.z.toInt());
    }

    final corners = [
      toWorldPos(Vector3(minGridX.toDouble(), minGridY.toDouble(), 0)) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(minGridX.toDouble(), maxGridY.toDouble(), 0)) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(maxGridX.toDouble(), minGridY.toDouble(), 0)) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(maxGridX.toDouble(), maxGridY.toDouble(), 0)) -
          Vector2(tilesize.x / 2, 0),
    ];
    double minX = corners.map((c) => c.x).reduce(math.min);
    double minY = corners.map((c) => c.y).reduce(math.min);
    double maxX = corners.map((c) => c.x).reduce(math.max);
    double maxY = corners.map((c) => c.y).reduce(math.max);

    double padTop = zHeightUsedPixels.toDouble();
    double padBottom = (maxZ.toDouble() * tilesize.z) + tilesize.z.toDouble();

    final width = (maxX - minX + tilesize.x).ceil();
    final height = (maxY - minY + padTop + padBottom).ceil();

    albedoWorldTopLeft = Vector2(minX, minY - padTop);
    albedoWidth = math.max(1, width);
    albedoHeight = math.max(1, height + tilesize.z.toInt());
  }

  bool startedBuildingMaps = false;
  void buildImageMaps(List<IsometricRenderable> additionals) {
    if((albedoMap == null || normalAndDepthMap == null) && startedBuildingMaps) return;
    startedBuildingMaps = true;

    PictureRecorder albedoRecorder = PictureRecorder();
    PictureRecorder normalRecorder = PictureRecorder();
    Canvas albedoCanvas = Canvas(albedoRecorder);
    Canvas normalCanvas = Canvas(normalRecorder);

    renderMaps(albedoCanvas, normalCanvas, additionals);

    albedoRecorder.endRecording().toImage(albedoWidth, albedoHeight).then((value) {
      albedoMap?.dispose();
      albedoMap = value;
    });
    normalRecorder.endRecording().toImage(albedoWidth, albedoHeight).then((value) {
      normalAndDepthMap?.dispose();
      normalAndDepthMap = value;
    });
  }

  void renderMaps(Canvas albedoCanvas, Canvas normalCanvas, List<IsometricRenderable> additionals){
    if(albedoWorldTopLeft == null) return;

    albedoCanvas.save();
    normalCanvas.save();
    albedoCanvas.translate(-albedoWorldTopLeft!.x, -albedoWorldTopLeft!.y);
    normalCanvas.translate(-albedoWorldTopLeft!.x, -albedoWorldTopLeft!.y);

    double currentPaintZPos = double.infinity;

    int ti = 0, ei = 0;
    double tileDepth;
    double entityDepth = 0;
    int lastEntityIndex = -1;
    bool allEntitiesDone = false;
    bool allTilesDone = false;
    IsometricRenderable? currentRenderable;
    while (ti < tiles.length || ei < additionals.length) {
      if(ei != lastEntityIndex) {
        if(ei < additionals.length) {
          entityDepth = depth(additionals[ei]);
        } else {
          allEntitiesDone = true;
        }
        lastEntityIndex = ei;
      }

      tileDepth = depth(tiles.elementAtOrNull(ti));

      if ((tileDepth <= entityDepth || allEntitiesDone) && !allTilesDone) {
        currentRenderable = tiles.elementAtOrNull(ti++);
        if(currentRenderable == null) {
          allTilesDone = true;
          continue;
        }
        //if(!allEntitiesDone) {
        //  canvas.drawCircle(toWorldPos(tile.gridFeetPos).toOffset(), 3, Paint()
        //    ..color = Colors.blue);
        //  canvas.drawCircle(toWorldPos(tile.gridHeadPos).toOffset(), 3, Paint()
        //    ..color = Colors.blue);
        //}
      } else {
        currentRenderable = additionals[ei++];
      }

      if(currentRenderable.gridFeetPos.z != currentPaintZPos) {

      }

      currentRenderable.renderTree(albedoCanvas, normalCanvas, () => calculateNormalPaint(currentRenderable!));
    }
    albedoCanvas.restore();
    normalCanvas.restore();
  }
  Paint overridePaint = Paint()..isAntiAlias = false..filterQuality = FilterQuality.none;

  Paint calculateNormalPaint(IsometricRenderable renderable) {
    final double startVal =
        ((renderable.gridFeetPos.z - 1) / highestZTileInWorld) * 256;
    final double endVal = (renderable.gridFeetPos.z / highestZTileInWorld);

    overridePaint.colorFilter = ColorFilter.matrix([
      1, 0, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 0,
      endVal, 0, startVal, 0,
      0, 0, 1, 0,
    ]);
    return overridePaint;
  }

  bool containsRenderable(IsometricRenderable r) {
    double fx = r.gridFeetPos.x;
    double fy = r.gridFeetPos.y;
    double hx = r.gridHeadPos.x;
    double hy = r.gridHeadPos.y;
    return hx >= x * chunkSize &&
        fx < (x + 1) * chunkSize &&
        hy >= y * chunkSize &&
        fy < (y + 1) * chunkSize;
  }


  List<IsometricRenderable> currentAdditionalComponents = [];
  void render(
    Canvas canvas,
    Canvas normalCanvas,
    List<IsometricRenderable> components,
    NeighborChunkCluster neighborChunkCluster, [
    Offset offset = Offset.zero,
  ]) {
    if (isUsedByNeighbor) return;
    this.neighborChunkCluster = neighborChunkCluster;

    List<IsometricRenderable> newComponents = [];

    components.where((element) => element.dirty).forEach((element) {
      if (containsRenderable(element)) {
        newComponents.add(element);
        element.updatesNextFrame = true;
      }
    });
    if (newComponents.isNotEmpty) {
      currentAdditionalComponents = newComponents;
      renderMaps(canvas, normalCanvas, newComponents);
    } else if (albedoMap != null && normalAndDepthMap != null) {
      normalCanvas.drawImage(normalAndDepthMap!, offset, Paint());
      canvas.drawImage(albedoMap!, offset, Paint());
    }
  }
}