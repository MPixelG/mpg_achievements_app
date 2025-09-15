
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:image/image.dart' as img;
import 'package:mpg_achievements_app/components/level/isometric/isometric_tiled_component.dart';
import 'package:mpg_achievements_app/components/level/rendering/game_sprite.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

mixin IsometricShaderManager on IsometricTiledComponent{

  late FragmentProgram program;
  FragmentShader? shader;

  late Image tileset;
  late Image normalAndDepthTileset;

  late Image defaultNormalTexture;

  void initShaderProgram() async{
    program = await FragmentProgram.fromAsset("assets/shaders/lighting.frag");
    shader = program.fragmentShader();

    defaultNormalTexture = Flame.images.fromCache("Pixel_ArtTop_Down/basic_isometric_block_normal.png");
  }
  Paint paint = Paint();

  final mappedIndices = <int, int>{};

  void buildTilesets() async{
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

      Offset atlasPos = Offset(gridPosX * tilesize.x, gridPosY * tilesize.y);

      albedoCanvas.drawImage(value.texture, atlasPos, paint);

      if(value.normalTexture != null) {
        normalDepthCanvas.drawImage(value.normalTexture!, atlasPos, paint);
      } else {
        normalDepthCanvas.drawImage(defaultNormalTexture, atlasPos, paint);
      }

      mappedIndex++;
    }


    tileset = await albedoRecorder.endRecording().toImage((rows * tilesize.x).toInt(), (tilesize.y * cols).toInt());
    normalAndDepthTileset = await normalDepthRecorder.endRecording().toImage((width * tilesize.x).toInt(), (height * tilesize.y).toInt());

    Image testBild;

    Flame.images.load("testbild.png").then((value) {
      testBild = value;
    });
  }

  Future<Image> convertValuesToImage(List<double> vals, int width, int height) async{
    int pxCount = width * height;

    Uint8List bytes = Uint8List(pxCount);


    for (int i = 0; i < pxCount; i++) {
      double val = vals[i];

      int floatVal = (val * 255.0).round();
      floatVal.clamp(0, 255);
      bytes[i] = floatVal;
    }

    Completer<Image> completer = Completer();
    decodeImageFromList(bytes, (result) => completer.complete);

    return completer.future;
  }

  void convertTileDataToImage(){

    for(RenderInstance instance in gameTileMap.renderableTiles){




    }


  }





  Paint shaderPaint = Paint();
  void frame(Canvas canvas){
    if(shader == null) return;

    final double width = gameTileMap.tiledMap.width * tilesize.x;
    final double height = gameTileMap.tiledMap.height * tilesize.z;

    shader!.setImageSampler(0, image); //map data pixel => tile, r & g => tilesetIndex, b & a => normal and depth tileset index
    shader!.setImageSampler(1, tileset); //tileset (albedo)
    shader!.setImageSampler(2, normalAndDepthTileset); //tileset (normal and depth)


    shader!.setFloat(0, gameTileMap.tiledMap.width.toDouble()); //layerWidth
    shader!.setFloat(0, gameTileMap.tiledMap.height.toDouble()); //layerHeight
    shader!.setFloat(0, gameTileMap.totalZLayers.toDouble()); //zLayers


    shaderPaint.shader ??= shader!;
    canvas.drawRect(Rect.fromPoints(Offset.zero, Offset(width, height)), shaderPaint);
  }

}