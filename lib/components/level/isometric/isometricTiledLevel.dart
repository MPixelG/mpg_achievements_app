import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometricRenderable.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

/// A class representing a renderable instance with its rendering function, position, z-index, and other properties.
class RenderInstance {
  final void Function(Canvas, {Vector2 position, Vector2 size}) render;
  final Vector2 position;
  final Vector2 gridPos;
  final int zIndex;
  RenderInstance(this.render, this.position, this.zIndex, this.gridPos);
}

class IsometricTiledLevel extends TiledComponent{
  final List<RenderInstance> _tiles = [];

  IsometricTiledLevel(super.map);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _buildTileCache();
  }

  ///Builds a cache of tile render instances for efficient rendering.
  Future<void> _buildTileCache() async {
    final map = tileMap.map;
    final tileW = map.tileWidth.toDouble() / 2;
    final tileH = map.tileHeight.toDouble();

    int rawGid(int gid) => gid & 0x1FFFFFFF; // Clear flip bits

    Tileset findTileset(int gid) { //help function to find the correct tileset for a given gid
      final raw = rawGid(gid); // Clear flip bits
      Tileset? best; // The best match so far
      for (final ts in map.tilesets) { // Iterate through all tilesets
        if (ts.firstGid! <= raw) { // If this tileset could contain the gid
          if (best == null || ts.firstGid! > best.firstGid!) best = ts; // Update best if it's a better match
        }
      }
      if (best == null) { // If no tileset was found, throw an error
        throw StateError('No tileset found for gid $gid (raw $raw)');
      }
      return best; // Return the best match
    }

    int layerIndex = 0; // To keep track of the layer index for z-ordering
    for (final layer in map.layers) { // Iterate through all layers
      if (layer is TileLayer) { // Only process tile layers
        if (layer.chunks!.isNotEmpty) { // If the layer uses chunks
          for (final chunk in layer.chunks!) { // Iterate through all chunks
            final chunkData = chunk.data; //get the data
            final chunkWidth = chunk.width; //and the width
            final offsetX = chunk.x;
            final offsetY = chunk.y;
            for (int i = 0; i < chunkData.length; i++) { //all the chunk tiles
              final gid = chunkData[i]; //get the gid
              if (gid == 0) continue; //if its 0, it means its empty
              final x = (i % chunkWidth) + offsetX; //calculate the x and y position of the tile in the map
              final y = (i ~/ chunkWidth) + offsetY;
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
            await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH); //and add it to the cache
          }
        }

        layerIndex += 1; //increase the layer index for the next layer
      }
    }
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
    final raw = gid & 0x1FFFFFFF; // Clear flip bits
    final localIndex = raw - tileset.firstGid!; // Local index within the tileset

    Image img; //the tile texture set

    final path = tileset.image?.source?..replaceAll("../images", ""); //because the path in the tmx file is relative to the tmx file, but we need it relative to the assets folder
    img = await Flame.images.load(path ?? ""); //load the image from the tileset


    final cols = tileset.columns!; //amount of columns in the tileset image
    final row = localIndex ~/ cols; //calculate the row and column of the tile in the tileset image
    final col = localIndex % cols; //same for column
    final srcSize = Vector2(tileW*2, tileW*2); //the size of the tile in the tileset image

    final sprite = Sprite( //get the sprite for the tile
      img, //the tileset
      srcPosition: Vector2(col * 32, row * 32), //the position of the tile in the tileset image
      srcSize: srcSize, //and its size
    );

    final worldPos = orthogonalToIsometric(Vector2(tileX * tileW, tileY * tileW)) + Vector2(map.width * tileW, 0); //calculate the world position of the tile in the isometric world, also add an offset to center the map around the 0-point

    _tiles.add(RenderInstance(sprite.render, worldPos, tileZ, Vector2(tileX.toDouble(), tileY.toDouble()))); //convert those to render instance and add it to the list of tiles
  }

  List<RenderInstance>? lastRenderables;
  Iterable<IsometricRenderable>? lastComponents;
  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {

    if(lastComponents != components || lastRenderables == null) {
      lastComponents = components;
      lastRenderables = calculateSortedRenderInstances(components);
    }

    for (final r in lastRenderables!) { //render everything in the sorted order
      r.render(canvas, position: r.position - tileMap.destTileSize.xx / 2, size: tileMap.destTileSize.xx);
    }

  }

  List<RenderInstance> calculateSortedRenderInstances([Iterable<IsometricRenderable> additionals = const []]){
    final allRenderables = <RenderInstance>[]; //all the renderables that should be rendered, sorted by their z-index and position distance to the 0-point
    allRenderables.addAll(_tiles.asMap().entries.map((e) => e.value)); //add all tiles
    allRenderables.addAll(additionals.toList().map((e) => RenderInstance((c, {Vector2? position, Vector2? size}) => e.renderTree(c), e.position, e.renderPriority, e.gridFeetPos))); //add all given components to the list of renderables so that they are also sorted and rendered in the correct order


    allRenderables.sort((a, b) { //now we sort the renderables by their z-index and position
      Vector3 pos1 = Vector3(a.gridPos.x, a.gridPos.y, a.zIndex.toDouble()*tileMap.destTileSize.y);
      Vector3 pos2 = Vector3(b.gridPos.x, b.gridPos.y, b.zIndex.toDouble()*tileMap.destTileSize.y);

      int comparedPos = pos1.compareTo(pos2); //compare the foot y positions
      //if they are different, we take the comparison result (the one with the higher foot y is in front of the other)
      return comparedPos;
    });

    return allRenderables;
  }
}
extension on Vector2 {
  int compareTo(Vector2 gridPos) {
    return (distanceTo(Vector2.zero()).compareTo(gridPos.distanceTo(Vector2.zero())));
  }
}
extension on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(Vector3.zero()).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}