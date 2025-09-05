import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/level/isometric/isometricRenderable.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';


// A data class designed to hold all the necessary information for rendering a single object,
class RenderInstance {

  // A function reference that knows how to draw the object.
  final void Function(Canvas, {Vector2 position, Vector2 size}) render;
  final Vector2 position;
  final Vector2 gridPos;
  // The layer index from the Tiled map. This serves as the primary sorting key
  final int zIndex;
  // A flag to identify if this render instance is a dynamic component
  final bool isFrog;
  RenderInstance(this.render, this.position, this.zIndex, this.isFrog, this.gridPos);
}


// Instead of letting Flame render layer by layer, this component deconstructs the map
// into a list of individual `RenderInstance` objects
class IsometricTiledLevel extends TiledComponent{
  final List<RenderInstance> _tiles = [];

  IsometricTiledLevel(super.map);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Pre-build the tile cache for efficient rendering later reading data from the Tiled map (every layer every tile)
    await _buildTileCache();
  }

  Future<void> _buildTileCache() async {
    final map = tileMap.map;

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
    Tileset findTileset(int gid) {
      final raw = rawGid(gid);
      Tileset? best;
      for (final ts in map.tilesets) {
        if (ts.firstGid! <= raw) {
          if (best == null || ts.firstGid! > best.firstGid!) best = ts;
        }
      }
      if (best == null) {
        throw StateError('No tileset found for gid $gid (raw $raw)');
      }
      return best;
    }

    int layerIndex = 0;
    // Loop through all layers in the map.
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        // Tiled can store maps in chunks for performance. We need to handle both chunked (a list of smaller "chunked" objects and non-chunked (single massive array) layers.
        if (layer.chunks!.isNotEmpty) {
          for (final chunk in layer.chunks!) {
            final chunkData = chunk.data;
            final chunkWidth = chunk.width;
            final chunkHeight = chunk.height;
            final offsetX = chunk.x;
            final offsetY = chunk.y;
            for (int i = 0; i < chunkData.length; i++) {
              final gid = chunkData[i];
              if (gid == 0) continue; // Skip empty tiles
              // Calculate the tile's position within the overall map using chunk offsets.
              final x = (i % chunkWidth) + offsetX;
              final y = (i ~/ chunkWidth) + offsetY;
              // Add a render instance for this tile.
              await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH);
            }
          }
        } else {// Non-chunked layer
          final data = layer.data;
          final width = layer.width;
          for (int i = 0; i < data!.length; i++) {
            final gid = data[i];
            if (gid == 0) continue;
            final x = i % width;
            final y = i ~/ width;
            //add a render instance for this tile
            await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH);
          }
        }

        layerIndex += 1;
      }
    }
  }
  // This method creates a `RenderInstance` for a specific tile identified by its GID and adds it to the `_tiles` list.
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

    // Load the tileset image
    final path = tileset.image?.source?..replaceAll("../images", "");
    img = await Flame.images.load(path ?? "");

    // Calculate the tile's row and column within the tileset image
    final cols = tileset.columns!;
    final row = localIndex ~/ cols;
    final col = localIndex % cols;
    final srcSize = Vector2(32, 32);

    // Create a Sprite for the tile
    final sprite = Sprite(
      img,
      srcPosition: Vector2(col * 32, row * 32),
      srcSize: srcSize,
    );

    // Convert the tile's orthogonal grid coordinates to isometric world coordinates.
    final worldPos = orthogonalToIsometric(Vector2(tileX * 16, tileY * 16)) //transform orthogonal to screen position
        + Vector2(map.width * tileW, 0); //shift the map to the center of the screen to be all positive
    // Add the RenderInstance to our cache.
    _tiles.add(RenderInstance(sprite.render, worldPos, tileZ, false, Vector2(tileX.toDouble(), tileY.toDouble())));
  }

  final Paint paint = Paint()
    ..color = const Color(0x55FF0000)
    ..strokeWidth = 2.0;



  // This is the main custom render method, designed to be called by a parent component (like a World).
  // It takes a list of dynamic components, combines them with the cached static tiles,
  // performs a depth sort, and then renders everything in the correct order.
  void renderComponentsInTree(Canvas canvas, Iterable<IsometricRenderable> components) {

    final allRenderables = <RenderInstance>[];

    //all tiles are added to a list of renderables
    allRenderables.addAll(_tiles.asMap().entries.map((e) => e.value));

    //all dynamic components are added to the list of renderables
    //components are converted to RenderInstances in this case
   allRenderables.addAll(components.toList().map((e) => RenderInstance((c, {Vector2? position, Vector2? size}) =>
       e.renderTree(c), //flame standard render method is called
       e.position,
       e.renderPriority, //render priority is used as zIndex
       true,  e.gridFeetPos //the gridfeet position is used for sorting
   )));

    // Get the camera position to adjust rendering based on the viewport
    Vector2 cameraPosition = (game as PixelAdventure).cam.pos;

    //Core sorting loigic
    //1. Sort all renderables by zIndex
    allRenderables.sort((a, b) {
      int comparedZ = a.zIndex.compareTo(b.zIndex);
      if(comparedZ != 0){
        return comparedZ;
      }

      // Berechne die "Fußposition" des Sprites
      double footYA = a.gridPos.y + 32;
      double footYB = b.gridPos.y + 32;
      //2. then y-sort
      // For objects on the same layer, the one with the higher Y-value (further "down" the screen)
      // is drawn later, making it appear in front.
      int comparedY = footYA.compareTo(footYB);
      if (comparedY != 0) {
        return comparedY;
      }
      //3. finally x-sort
      // If two objects share the same Y-value, the one with the higher X-value (further "right" on the screen)
      // is drawn later, making it appear in front
      return a.gridPos.x.compareTo(b.gridPos.x);
    });

    // render the sorted list
    for (final entry in allRenderables) {
      final r = entry;
      //If r is a tile: The function being called is sprite.render.
      // If r is a component: The function being called is e.renderTree(c)

      r.render(canvas, position: r.position - Vector2(16,16), //r.position is the top-left corner, we need to offset it to the center of the tile
          size: Vector2(32,32)); //size of the tile is 32x32
    }

  }
}