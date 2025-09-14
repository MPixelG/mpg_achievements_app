import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../util/utils.dart';
import '../isometric/isometric_tiled_component.dart';
import 'game_sprite.dart';

class GameTileMap {

  late final Map<Vector3, int> _gids = {};

  int? getGidAt(Vector3 pos) => _gids[pos.clone()..floor()];

  final List<RenderInstance> renderableTiles = [];

  final Map<int, GameSprite> textures = {};

  GameSprite? getTextureAt(Vector3 pos) => textures[getGidAt(pos)];


  GameTileMap(TiledMap map){
    _buildTileCache(map);
  }

  Future<void> _buildTileCache(TiledMap map) async {
    // For a standard diamond isometric map, the visual width of a tile is half its source image width. Aspect ratio is 2:1.
    final tileW = map.tileWidth.toDouble() / 2;
    final tileH = map.tileHeight.toDouble();

    // Helper function to remove the flip/rotation flags from a tile's GID (Global ID).
    //strips away the flip/rotation flags from a tile's GID (Global ID).
    //10000000 00000000 00000000 01001010  (The GID from Tiled for  horizontally flipped tile #74)
    // & 00011111 11111111 11111111 11111111  (The mask 0x1FFFFFFF)
    //   -----------------------------------
    //   00000000 00000000 00000000 01001010  (The Result)

    int rawGid(int gid) => gid & 0x1FFFFFFF;

    // Helper function to find which Tileset a specific GID belongs to.
    // This is necessary because a map can use multiple tilesets.
    Tileset findTileset(int gid) { //help function to find the correct tileset for a given gid
      final raw = rawGid(gid);// Clear flip bits
      Tileset? best;// The best match so far
      for (final ts in map.tilesets) {// Iterate through all tilesets
        if (ts.firstGid! <= raw) {// If this tileset could contain the gid
          if (best == null || ts.firstGid! > best.firstGid!) best = ts;// Update best if it's a better match
        }
      }
      if (best == null) {
        throw StateError('No tileset found for gid $gid (raw $raw)');
      }
      return best;
    }

    int layerIndex = 0;
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
              _gids[Vector3(x.toDouble(), y.toDouble(), layerIndex.toDouble())] = gid;
              await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH); //and add it to the cache
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
            _gids[Vector3(x.toDouble(), y.toDouble(), layerIndex.toDouble())] = gid;
            await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH); //and add it to the cache
          }
        }

        layerIndex += 1; //increase the layer index for the next layer
      }
    }

    print(textures[_gids[Vector3.zero()]]?.sprite.srcPosition);
  }

  ///Adds a tile to the render cache based on its GID and position.
  Future<void> _addTileForGid(
      TiledMap map,
      Tileset tileset,
      int gid,
      int tileX,
      int tileY,
      int tileZ,
      double tileW,
      double tileH,
      ) async {
    final raw = gid & 0x1FFFFFFF;
    //calculate the local index of the tile within its tileset
    final localIndex = raw - tileset.firstGid!;

    Image img;
    Image normalMapImg;

    // Load the tileset image
    final path = tileset.image?.source?..replaceAll("../images", "");
    img = Flame.images.fromCache(path ?? "");

    //final String normalMapPath = "${(tileset.image?.source?..replaceAll("../images", ""))?..replaceAll(".png", "")}_normalMap.png";

    final String normalMapPath = "${RegExp("../images/([A-Za-z_0-9/]+).png").firstMatch(tileset.image!.source!)!.group(1)!}_normalMap.png";
    normalMapImg = Flame.images.fromCache(normalMapPath);


    final cols = tileset.columns!; //amount of columns in the tileset image
    final row = localIndex ~/ cols; //calculate the row and column of the tile in the tileset image
    final col = localIndex % cols; //same for column
    final srcSize = Vector2(tileW*2, tileW*2); //the size of the tile in the tileset image

    final sprite = Sprite( //get the sprite for the tile
      img, //the tileset
      srcPosition: Vector2(col * tilesize.x, row * tilesize.y), //the position of the tile in the tileset image
      srcSize: srcSize, //and its size
    );
    final normalSprite = Sprite( //get the sprite for the tile
      normalMapImg, //the tileset
      srcPosition: Vector2(col * tilesize.x, row * tilesize.y), //the position of the tile in the tileset image
      srcSize: srcSize, //and its size
    );

    // Convert the tile's orthogonal grid coordinates to isometric world coordinates.
    final worldPos = orthogonalToIsometric(Vector2(tileX * tilesize.z, tileY * tilesize.z)) //transform orthogonal to screen position
        + Vector2(map.width * tileW, 0); //shift the map to the center of the screen to be all positive
    // Add the RenderInstance to our cache.

    textures[gid] = GameSprite(sprite);
    renderableTiles.add(RenderInstance(sprite.render, worldPos, tileZ, Vector2(tileX.toDouble(), tileY.toDouble()), RenderCategory.tile, await getTileFromTilesetToImage(sprite), await getTileFromTilesetToImage(normalSprite)));
  }

  Future<Image> getTileFromTilesetToImage(Sprite sprite) async{

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    sprite.render(canvas);

    final picture = recorder.endRecording();
    final img = await picture.toImage(tilesize.x.toInt(), tilesize.y.toInt());
    return img;

  }


}