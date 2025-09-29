import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/util/isometric_utils.dart';
import 'package:mpg_achievements_app/core/level/rendering/tileset_utils.dart';

import '../../../mpg_pixel_adventure.dart';
import '../isometric/isometric_renderable.dart';
import '../isometric/isometric_tiled_component.dart';
import 'game_sprite.dart';
import 'game_tile_map.dart';

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
  void reSortTiles(
    Iterable<IsometricRenderable> additionals, {
    Iterable<IsometricRenderable>? neighborChunkTiles,
  }) {
    allRenderables.clear();

    allRenderables.addAll(tiles);
    allRenderables.addAll(additionals);

    if (neighborChunkTiles != null) {
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

  int currentlyActiveOperations = 0;
  static const int maxOperations = 10;
  Future<void> rebuildMaps(Iterable<IsometricRenderable> additionals) async {
    if(currentlyActiveOperations > maxOperations) return;

    currentlyActiveOperations++;
    Iterable<IsometricRenderable> containedAdditionals = additionals
        .toList()
        .where((element) => containsRenderable(element));

    if (neighborChunkCluster != null) {
      usesTempNeighborTileRendering = true;

      List<IsometricRenderable> neighborChunkTiles = [];
      List<Chunk> neighborChunks = [];

      for (var value in additionals) {
        neighborChunks.addAll(neighborChunkCluster!.getWhereContained(value));
      }

      for (var n in neighborChunks) {
        n.isUsedByNeighbor = true;
      }
      usesTempNeighborTileRendering = neighborChunks.isNotEmpty;

      for (var element in neighborChunks) {
        neighborChunkTiles.addAll(element.tiles);
      }

      reSortTiles(containedAdditionals, neighborChunkTiles: neighborChunkTiles);
    } else {
      usesTempNeighborTileRendering = false;
      reSortTiles(containedAdditionals);
    }
    await prepareBuildImageMaps().then((value) async {
      await buildAlbedoMap(containedAdditionals);
      await buildNormalAndDepthMap(containedAdditionals);
    }).then((value) => currentlyActiveOperations--);
  }

  Future<void> prepareBuildImageMaps() async {
    if (allRenderables.isEmpty) return;

    int minGridX = 1 << 30, minGridY = 1 << 30;
    int maxGridX = -1 << 30, maxGridY = -1 << 30;
    int maxZ = 0;
    for (final r in allRenderables) {
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
    albedoHeight = math.max(1, height);
  }

  Vector2 getStartRenderPos([int? correctedX, int? correctedY]) {
    return toWorldPos(
          Vector3(
            ((correctedX ?? x) - 1) * chunkSize.toDouble(),
            (correctedY ?? y) * chunkSize.toDouble(),
            0,
          ),
        ) +
        Vector2(0, (tilesize.z * chunkSize / 2) - zHeightUsedPixels);
  }

  void adjustRenderingBounds(
    Vector2 gridPos,
    Vector2 bottomRightPos,
    Iterable<IsometricRenderable> additionals,
  ) {
    bool l = false;
    bool r = false;
    bool t = false;
    bool b = false;

    for (final element in additionals) {
      if (!(b && r) &&
          (neighborChunkCluster?.bottomRight?.containsRenderable(element) ??
              false)) {
        b = true;
        r = true;
      }
      if (!(b && l) &&
          (neighborChunkCluster?.bottomLeft?.containsRenderable(element) ??
              false)) {
        b = true;
        l = true;
      }
      if (!(t && r) &&
          (neighborChunkCluster?.topRight?.containsRenderable(element) ??
              false)) {
        t = true;
        r = true;
      }
      if (!(t && l) &&
          (neighborChunkCluster?.topLeft?.containsRenderable(element) ??
              false)) {
        t = true;
        l = true;
      }
      if (!t &&
          (neighborChunkCluster?.top?.containsRenderable(element) ?? false)) {
        t = true;
      }
      if (!b &&
          (neighborChunkCluster?.bottom?.containsRenderable(element) ??
              false)) {
        b = true;
      }
      if (!r &&
          (neighborChunkCluster?.right?.containsRenderable(element) ?? false)) {
        r = true;
      }
      if (!l &&
          (neighborChunkCluster?.left?.containsRenderable(element) ?? false)) {
        l = true;
      }
    }

    if (l) {
      gridPos.x--;
    }
    if (t) {
      gridPos.y--;
    }

    if (r) {
      bottomRightPos.x *= 2;
    }
    if (b) {
      bottomRightPos.y *= 2;
    }
  }

  Future<void> buildAlbedoMap(Iterable<IsometricRenderable> additionals) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.save();


    canvas.translate(-albedoWorldTopLeft!.x, -albedoWorldTopLeft!.y);
    for (final tile in allRenderables) {
      tile.renderAlbedo(canvas);
    }
    canvas.restore();


    //canvas.drawRect(Offset.zero & Size(albedoWidth.toDouble(), albedoHeight.toDouble()), Paint()..color = Color(hashCode).withValues(alpha: 0.5));

    final picture = recorder.endRecording();
    albedoMap = await picture.toImage(albedoWidth, albedoHeight);
  }

  Future<void> buildNormalAndDepthMap(
    Iterable<IsometricRenderable> additionals,
  ) async {
    final normalRecorder = PictureRecorder();
    final normalCanvas = Canvas(normalRecorder);
    normalCanvas.save();
    normalCanvas.translate(-albedoWorldTopLeft!.x, -albedoWorldTopLeft!.y);

    for (final tile in allRenderables) {
      if (tile.renderNormal == null) continue;

      final double startVal =
          ((tile.gridFeetPos.z - 1) / highestZTileInWorld) * 256;
      final double endVal = (tile.gridFeetPos.z / highestZTileInWorld);

      tile.renderNormal!(
        normalCanvas,
        Paint()
          ..colorFilter = ColorFilter.matrix([
            1, 0, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 0,
            endVal, 0, startVal, 0,
            0, 0, 1, 0,
          ]),
      );
    }
    normalCanvas.restore();

    final normalPicture = normalRecorder.endRecording();
    normalAndDepthMap = await normalPicture.toImage(albedoWidth, albedoHeight);
  }

  Vector2 toLocalPos(Vector2 gridPos, {double layerIndex = 0}) {
    gridPos -= Vector2(x.toDouble() * chunkSize, y.toDouble() * chunkSize);

    final localPoint = Vector2(
      (gridPos.x - gridPos.y + (chunkSize)) * (tilesize.x / 2),
      (gridPos.x + gridPos.y) * (tilesize.z / 2),
    );

    final layerOffset = Vector2(
      -tilesize.x / 2,
      zHeightUsedPixels - (0.0 * layerIndex * tilesize.z / 32),
    );

    return localPoint + layerOffset;
  }

  bool containsRenderable(IsometricRenderable r) {
    double fx = r.gridFeetPos.x;
    double fy = r.gridFeetPos.y;
    return fx >= x * chunkSize &&
        fx < (x + 1) * chunkSize &&
        fy >= y * chunkSize &&
        fy < (y + 1) * chunkSize;
  }


  Set<IsometricRenderable> currentAdditionalComponents = {};
  void render(
    Canvas canvas,
    Canvas normalCanvas,
    Iterable<IsometricRenderable> components,
    NeighborChunkCluster neighborChunkCluster, [
    Offset offset = Offset.zero,
  ]) {
    if (isUsedByNeighbor) return;
    this.neighborChunkCluster = neighborChunkCluster;

    Set<IsometricRenderable> newComponents = {};

    components.where((element) => element.dirty).forEach((element) {
      if (containsRenderable(element)) {
        newComponents.add(element);
        element.updatesNextFrame = true;
      }
    });

    if (newComponents.isNotEmpty || currentAdditionalComponents.isNotEmpty) {
      currentAdditionalComponents = newComponents;
      rebuildMaps(currentAdditionalComponents);
    }

    if (albedoMap != null && normalAndDepthMap != null) {
      canvas.drawImage(albedoMap!, offset, Paint());
      normalCanvas.drawImage(normalAndDepthMap!, offset, Paint());
    }
  }



  static Set<Tileset> knownTilesets = {};
  static const int chunkSize = 16; // Size of each chunk in tiles
  static int totalZLayers = 1;
}

class ChunkTile with IsometricRenderable {
  final int gid;
  final int localX;
  final int localY;
  final int worldX;
  final int worldY;
  final int z;
  int zAdjustPos;

  Vector3 get posWorld =>
      Vector3(worldX.toDouble(), worldY.toDouble(), z.toDouble());
  Vector3 get posLocal =>
      Vector3(localX.toDouble(), localY.toDouble(), z.toDouble());

  ChunkTile(
    this.gid,
    this.localX,
    this.localY,
    this.worldX,
    this.worldY,
    this.z,
    this.zAdjustPos,
  ){
    Future.microtask(() {
      loadTextureOfGid(gid);
    });
  }

  GameSprite get cachedSprite => textures[gid]!;

  bool loadingSprite = false;

  @override
  Vector3 get gridFeetPos => posWorld;

  @override
  Vector3 get gridHeadPos => gridFeetPos + Vector3(1, 1, 1);

  @override
  RenderCategory get renderCategory => RenderCategory.tile;

  @override
  void Function(Canvas canvas) get renderAlbedo {
    return (Canvas canvas) async {
      Vector2 position = toWorldPos(posWorld) - Vector2(tilesize.x / 2, 0);
      cachedSprite.albedo.render(canvas, position: position);
    };
  }

  @override
  void Function(Canvas canvas, Paint? overridePaint)? get renderNormal {
    return (Canvas canvas, Paint? overridePaint) async {
      Vector2 position = toWorldPos(posWorld) - Vector2(tilesize.x / 2, 0);
      cachedSprite.normalAndDepth?.render(
        canvas,
        position: position,
        overridePaint: overridePaint,
      );
    };
  }
}

Map<int, GameSprite> textures = {};
List<int> currentOperations = [];
void loadTextureOfGid(int gid) async {
  if(currentOperations.contains(gid)){
    return;
  }
  currentOperations.add(gid);

  Tileset tileset = findTileset(gid, Chunk.knownTilesets);
  Image tilesetImage = (await getImageFromTileset(tileset))!;
  Image normalMapImg = (await getNormalImageFromTileset(tileset))!;

  final raw = gid & 0x1FFFFFFF;
  //calculate the local index of the tile within its tileset
  final localIndex = raw - tileset.firstGid!;

  final cols = tileset.columns!; //amount of columns in the tileset image
  final row =
      localIndex ~/
      cols; //calculate the row and column of the tile in the tileset image
  final col = localIndex % cols; //same for column
  final srcSize = tilesize.xy; //the size of the tile in the tileset image

  final sprite = Sprite(
    //get the sprite for the tile
    tilesetImage, //the tileset
    srcPosition: Vector2(
      col * tilesize.x,
      row * tilesize.y,
    ), //the position of the tile in the tileset image
    srcSize: srcSize, //and its size
  );
  final normalSprite = Sprite(
    //get the sprite for the tile
    normalMapImg, //the tileset
    srcPosition: Vector2(
      col * tilesize.x,
      row * tilesize.y,
    ), //the position of the tile in the tileset image
    srcSize: srcSize, //and its size
  );

  textures[gid] = GameSprite(sprite, normalSprite);;
}

extension VectorComparing on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(
      Vector3.zero(),
    ).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}

class NeighborChunkCluster {
  Chunk? top;
  Chunk? right;
  Chunk? left;
  Chunk? bottom;
  Chunk? topRight;
  Chunk? topLeft;
  Chunk? bottomRight;
  Chunk? bottomLeft;
  NeighborChunkCluster({
    this.top,
    this.right,
    this.left,
    this.bottom,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  List<Chunk> getWhereContained(IsometricRenderable renderable) {
    List<Chunk> out = [];

    if (top != null && top!.containsRenderable(renderable)) out.add(top!);
    if (right != null && right!.containsRenderable(renderable)) out.add(right!);
    if (left != null && left!.containsRenderable(renderable)) out.add(left!);
    if (bottom != null && bottom!.containsRenderable(renderable)) {
      out.add(bottom!);
    }
    if (topRight != null && topRight!.containsRenderable(renderable)) {
      out.add(topRight!);
    }
    if (topLeft != null && topLeft!.containsRenderable(renderable)) {
      out.add(topLeft!);
    }
    if (bottomRight != null && bottomRight!.containsRenderable(renderable)) {
      out.add(bottomRight!);
    }
    if (bottomLeft != null && bottomLeft!.containsRenderable(renderable)) {
      out.add(bottomLeft!);
    }

    return out;
  }
}
