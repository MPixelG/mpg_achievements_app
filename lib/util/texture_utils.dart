import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' hide Chunk;
import 'package:mpg_achievements_app/core/level/rendering/chunk.dart';
import 'package:mpg_achievements_app/core/level/rendering/game_sprite.dart';
import 'package:mpg_achievements_app/util/tileset_utils.dart';

import '../mpg_pixel_adventure.dart';

Map<int, GameSprite> textures = {};
List<int> currentOperations = [];
void loadTextureOfGid(int gid) async {
  if(textures.containsKey(gid) || currentOperations.contains(gid)){
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

  textures[gid] = GameSprite(sprite, normalSprite);
}