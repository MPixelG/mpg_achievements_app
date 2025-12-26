import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../isometric/isometric_renderable.dart';
import 'chunk_tile.dart';
import 'game_tile_map.dart';
import 'neighbor_chunk_cluster.dart';
import 'new_chunk_grid.dart';

class Chunk {
  final int x;
  final int y;
  final int z;

  NeighborChunkCluster? neighborChunkCluster;
  bool usesTempNeighborTileRendering = false;
  bool isUsedByNeighbor = false;

  Vector2? albedoWorldTopLeft;
  int albedoWidth = 1;
  int albedoHeight = 1;

  int yHeightUsedPixels = 0;
  static int highestYTileInWorld = 0;

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
      x += y;
      z += y;

      final chunkX = x ~/ chunkSize;
      final chunkZ = z ~/ chunkSize;

      if (chunkX == this.x && chunkZ == this.z) {
        final localX = x - chunkX * chunkSize;
        final localZ = z - chunkZ * chunkSize;

        final int topPos = (y * tilesize.z).toInt();
        if (gid != 0 && topPos > yHeightUsedPixels) {
          yHeightUsedPixels = topPos;
        }
        if (y > highestYTileInWorld) {
          highestYTileInWorld = y;
        }

        tiles.add(ChunkTile(gid, localX, localZ, x, z, y, 0));
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
            final offsetZ = chunk.y;
            for (int i = 0; i < chunkData.length; i++) {
              //all the chunk tiles
              final gid = chunkData[i]; //get the gid
              if (gid == 0) continue; //if its 0, it means its empty

              final x = (i % chunkWidth) + offsetX; //calculate the x and y position of the tile in the map
              final z = (i ~/ chunkWidth) + offsetZ;

              registerTile(gid, x, layerIndex, z);
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
            final x = i % width; //calculate the x and y position of the tile in the map
            final z = i ~/ width;
            registerTile(gid, x, layerIndex, z);
          }
        }

        layerIndex += 1; //increase the layer index for the next layer
      }
    }
    totalZLayers = layerIndex;

    for (var element in tiles) {
      element.yAdjustPos = yHeightUsedPixels;
    }

    reSortTiles([]);
    Future.delayed(const Duration(seconds: 1), () => rebuildMaps([]));
  }

  static Vector2 worldSize = Vector2.zero();

  List<IsometricRenderable> allRenderables = [];
  void reSortTiles(Iterable<IsometricRenderable> additionals) {
    tiles.sort((a, b) => depth(a).compareTo(depth(b)));
  }

  int currentlyActiveOperations = 0;
  static const int maxOperations = 5;
  void rebuildMaps(List<IsometricRenderable> additionals) {
    if(currentlyActiveOperations > maxOperations) return;

    currentlyActiveOperations++;
    final List<IsometricRenderable> containedAdditionals = additionals
        .where((element) => containsRenderable(element)).toList();

    if (neighborChunkCluster != null) {
      usesTempNeighborTileRendering = true;

      final List<IsometricRenderable> neighborChunkTiles = [];
      final List<Chunk> neighborChunks = [];

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

    int minGridX = 1 << 30, minGridZ = 1 << 30;
    int maxGridX = -1 << 30, maxGridZ = -1 << 30;
    int maxY = 0;
    for (final r in tiles) {
      minGridX = math.min(minGridX, r.gridFeetPos.x.toInt());
      minGridZ = math.min(minGridZ, r.gridFeetPos.z.toInt());
      maxGridX = math.max(maxGridX, r.gridHeadPos.x.toInt());
      maxGridZ = math.max(maxGridZ, r.gridHeadPos.z.toInt());
      maxY = math.max(maxY, r.gridHeadPos.y.toInt());
    }

    final corners = [
      toWorldPos(Vector3(minGridX.toDouble(), 0, minGridZ.toDouble())) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(minGridX.toDouble(), 0, maxGridZ.toDouble())) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(maxGridX.toDouble(), 0, minGridZ.toDouble())) -
          Vector2(tilesize.x / 2, 0),
      toWorldPos(Vector3(maxGridX.toDouble(), 0, maxGridZ.toDouble())) -
          Vector2(tilesize.x / 2, 0),
    ];
    final double minX = corners.map((c) => c.x).reduce(math.min);
    final double minZ = corners.map((c) => c.y).reduce(math.min);
    final double maxX = corners.map((c) => c.x).reduce(math.max);
    final double maxZ = corners.map((c) => c.y).reduce(math.max);

    final double padTop = yHeightUsedPixels.toDouble() + tilesize.z;
    final double padBottom = (maxY.toDouble() * tilesize.z) + tilesize.z.toDouble();

    final width = (maxX - minX + tilesize.x).ceil();
    final height = (maxZ- minZ + padTop + padBottom).ceil();

    albedoWorldTopLeft = Vector2(minX, minZ - padTop);
    albedoWidth = math.max(1, width);
    albedoHeight = math.max(1, height + tilesize.z.toInt());
  }

  bool startedBuildingMaps = false;
  void buildImageMaps(List<IsometricRenderable> additionals) {
    if((albedoMap == null || normalAndDepthMap == null) && startedBuildingMaps) return;
    startedBuildingMaps = true;

    final PictureRecorder albedoRecorder = PictureRecorder();
    final PictureRecorder normalRecorder = PictureRecorder();
    final Canvas albedoCanvas = Canvas(albedoRecorder);
    final Canvas normalCanvas = Canvas(normalRecorder);

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

    const double currentPaintYPos = double.infinity;

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

      if(currentRenderable.gridFeetPos.y != currentPaintYPos) {

      }

      currentRenderable.renderTree(albedoCanvas, normalCanvas, () => calculateDepthPaint(currentRenderable!, overridePaint));
    }
    albedoCanvas.restore();
    normalCanvas.restore();
  }
  Paint overridePaint = Paint()..isAntiAlias = false..filterQuality = FilterQuality.none;

  bool containsRenderable(IsometricRenderable r) {
    final double fx = r.gridFeetPos.x;
    final double fz = r.gridFeetPos.z;
    final double hx = r.gridHeadPos.x;
    final double hz = r.gridHeadPos.z;


    final bool smallerX = fx < (x+1)*chunkSize;
    final bool smallerZ = fz < (z+1)*chunkSize;
    final bool greaterX = hx >= x*chunkSize;
    final bool greaterZ = hz >= z*chunkSize;

    return smallerX && smallerZ && greaterX && greaterZ;
  }


  List<IsometricRenderable> currentAdditionalComponents = [];
  void render(
    Canvas canvas,
    Canvas normalCanvas,
    [ List<IsometricRenderable>? components,
    NeighborChunkCluster? neighborChunkCluster,
    Offset offset = Offset.zero,
  ]) {
    if (isUsedByNeighbor) return;
    this.neighborChunkCluster = neighborChunkCluster;

    final List<IsometricRenderable> newComponents = [];
    components ??= [];

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
      //print("drawing image maps");
      normalCanvas.drawImage(normalAndDepthMap!, offset, Paint());
      canvas.drawImage(albedoMap!, offset, Paint());
    }
  }
}