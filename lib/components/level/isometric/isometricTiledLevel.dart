import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:mpg_achievements_app/components/util/utils.dart';

class RenderInstance {
  final Sprite sprite;
  final Vector2 position;
  final int zIndex;
  RenderInstance(this.sprite, this.position, this.zIndex);
}

class IsometricTiledLevel extends TiledComponent {
  final List<RenderInstance> _tiles = [];

  IsometricTiledLevel(super.map);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _buildTileCache();
  }

  Future<void> _buildTileCache() async {
    final map = tileMap.map;
    final tileW = map.tileWidth.toDouble() / 2;
    final tileH = map.tileHeight.toDouble();

    int rawGid(int gid) => gid & 0x1FFFFFFF;

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
    for (final layer in map.layers) {
      if (layer is TileLayer) {
        if (layer.chunks!.isNotEmpty) {
          for (final chunk in layer.chunks!) {
            final chunkData = chunk.data;
            final chunkWidth = chunk.width;
            final chunkHeight = chunk.height;
            final offsetX = chunk.x;
            final offsetY = chunk.y;
            for (int i = 0; i < chunkData.length; i++) {
              final gid = chunkData[i];
              if (gid == 0) continue;
              final x = (i % chunkWidth) + offsetX;
              final y = (i ~/ chunkWidth) + offsetY;
              await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH);
            }
          }
        } else {
          final data = layer.data;
          final width = layer.width;
          for (int i = 0; i < data!.length; i++) {
            final gid = data[i];
            if (gid == 0) continue;
            final x = i % width;
            final y = i ~/ width;
            await _addTileForGid(map, findTileset(gid), gid, x, y, layerIndex, tileW, tileH);
          }
        }
        layerIndex++;
      }
    }
  }

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
    final localIndex = raw - tileset.firstGid!;

    Image img;

    final path = tileset.image?.source?..replaceAll("../images", "");
    img = await Flame.images.load(path ?? "");


    final cols = tileset.columns!;
    final row = localIndex ~/ cols;
    final col = localIndex % cols;
    final srcSize = Vector2(32, 32);


    final sprite = Sprite(
      img,
      srcPosition: Vector2(col * 32, row * 32),
      srcSize: srcSize,
    );

    final worldPos = orthogonalToIsometric(Vector2(tileX * 16, tileY * 16)) + Vector2(map.width * tileW, 0);

    _tiles.add(RenderInstance(sprite, worldPos, tileZ));
  }

  final Paint paint = Paint()
    ..color = const Color(0x55FF0000)
    ..strokeWidth = 2.0;
  @override
  void render(Canvas canvas) {

    for (final tile in _tiles) {
      tile.sprite.render(
        canvas,
        position: tile.position - Vector2(16, 16),
        size: Vector2(32, 32),
      );

    }
  }
}
