import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../isometric/isometric_renderable.dart';
import 'game_sprite.dart';
import 'game_tile_map.dart';

class IsometricShaderManager {
  late FragmentProgram program;
  FragmentShader? shader;

  Image? tileset;
  Image? normalAndDepthTileset;
  Image? tileData;

  late Image defaultNormalTexture;

  GameTileMap gameTileMap;

  IsometricShaderManager(this.gameTileMap) {
    init();
  }

  void initShaderProgram() async {
    program = await FragmentProgram.fromAsset("assets/shaders/lighting.frag");
    shader = program.fragmentShader();

    defaultNormalTexture = Flame.images.fromCache(
      "Pixel_ArtTop_Down/basic_isometric_block_normal.png",
    );
  }

  Paint paint = Paint();

  void init() {
    initShaderProgram();
    buildTilesets();
    convertTileDataToImage();
  }

  final mappedIndices = <int, int>{};
  void buildTilesets() async {
    PictureRecorder albedoRecorder = PictureRecorder();
    PictureRecorder normalDepthRecorder = PictureRecorder();

    Canvas albedoCanvas = Canvas(albedoRecorder);
    Canvas normalDepthCanvas = Canvas(normalDepthRecorder);

    int mappedIndex = 1; //1 because a gid of 0 means its empty
    final int totalTilesetEntries = gameTileMap.textures.length;

    int cols = sqrt(totalTilesetEntries).ceil();
    int rows = (totalTilesetEntries / cols).ceil();

    for (var entry in gameTileMap.textures.entries) {
      MapEntry<int, GameSprite> newEntry = entry;
      GameSprite value = newEntry.value;

      mappedIndices[newEntry.key] = mappedIndex;

      int gridPosX = mappedIndex % rows;
      int gridPosY = mappedIndex ~/ rows;

      Vector2 atlasPos = Vector2(gridPosX * tilesize.x, gridPosY * tilesize.y);

      value.albedo.render(albedoCanvas, position: atlasPos);

      if (value.normalAndDepth != null) {
        value.albedo.render(normalDepthCanvas, position: atlasPos);
      } else {
        normalDepthCanvas.drawImage(
          defaultNormalTexture,
          atlasPos.toOffset(),
          paint,
        );
      }

      mappedIndex++;
    }

    tileset = await albedoRecorder.endRecording().toImage(
      (rows * tilesize.x).toInt(),
      (tilesize.y * cols).toInt(),
    );
    normalAndDepthTileset = await normalDepthRecorder.endRecording().toImage(
      (rows * tilesize.x).toInt(),
      (cols * tilesize.y).toInt(),
    );
  }

  Future<Image> convertValuesToImage(
    List<int> vals,
    int width,
    int height,
  ) async {
    int pxCount = width * height;

    Uint8List bytes = Uint8List(pxCount);

    for (int i = 0; i < pxCount; i++) {
      bytes[i] = vals[i].clamp(0, 255);
    }

    Completer<Image> completer = Completer();
    decodeImageFromList(bytes, (result) => completer.complete);

    return completer.future;
  }

  void convertTileDataToImage() async {
    int rows = gameTileMap.tiledMap.width;
    int cols = gameTileMap.tiledMap.height;

    int length = rows * cols * 4 * gameTileMap.totalZLayers;

    List<int> data = List.generate(length, (index) {
      int result = 0;

      double tileIndex = (index ~/ 4).toDouble();

      double layerTileIndex = (tileIndex % (rows * cols)).floorToDouble();

      double gridX = layerTileIndex % cols;
      double gridY = (layerTileIndex ~/ cols).toDouble();
      double gridZ = (tileIndex ~/ gameTileMap.totalZLayers).toDouble();

      int? gid = gameTileMap.getGidAt(Vector3(gridX, gridY, gridZ));
      if (gid == null) {
        print("no gid found at $gridX, $gridY, $gridZ");
      }

      int? transformedGid = mappedIndices[gid];
      if (transformedGid == null) {
        print("no transformed gid found at $gridX, $gridY, $gridZ");
      }

      switch (index % 4) {
        case 0:
          {
            // tile index
            print("gid1: ${transformedGid! & 0xFFFFFFFF00000000}");
            return transformedGid & 0xFFFFFFFF00000000;
          }
        case 1:
          {
            // tile index 2
            print("gid2: ${transformedGid! & 0x00000000FFFFFFFF}");
            return transformedGid & 0x00000000FFFFFFFF;
          }
        case 2:
          {
            // normal index
            print("normal gid1: ${transformedGid! & 0xFFFFFFFF00000000}");
            return transformedGid & 0xFFFFFFFF00000000;
          }
        case 3:
          {
            // normal index 2
            print("normal gid2: ${transformedGid! & 0x00000000FFFFFFFF}");
            return transformedGid & 0x00000000FFFFFFFF;
          }
      }
      return result;
    });

    tileData = await convertValuesToImage(
      data,
      rows,
      cols * gameTileMap.totalZLayers,
    );
  }

  Paint shaderPaint = Paint();
  void frame(Canvas canvas, Iterable<IsometricRenderable> components) {
    if (shader == null ||
        tileData == null ||
        tileset == null ||
        normalAndDepthTileset == null)
      return;
    print("passed!");

    final double width = gameTileMap.tiledMap.width * tilesize.x;
    final double height = gameTileMap.tiledMap.height * tilesize.z;

    shader!.setImageSampler(
      0,
      tileData!,
    ); //map data pixel => tile, r & g => tilesetIndex, b & a => normal and depth tileset index
    shader!.setImageSampler(1, tileset!); //tileset (albedo)
    shader!.setImageSampler(
      2,
      normalAndDepthTileset!,
    ); //tileset (normal and depth)

    shader!.setFloat(0, gameTileMap.tiledMap.width.toDouble()); //layerWidth
    shader!.setFloat(0, gameTileMap.tiledMap.height.toDouble()); //layerHeight
    shader!.setFloat(0, gameTileMap.totalZLayers.toDouble()); //zLayers

    shaderPaint.shader ??= shader!;
    canvas.drawRect(
      Rect.fromPoints(Offset.zero, Offset(width, height)),
      shaderPaint,
    );
  }
}
