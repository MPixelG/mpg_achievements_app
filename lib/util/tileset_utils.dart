import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../mpg_pixel_adventure.dart';

Map<int, Tileset> _tilesetCache = {};
Tileset findTileset(int gid, Iterable<Tileset> tilesets) {
  //help function to find the correct tileset for a given gid
  if (_tilesetCache[gid] != null) return _tilesetCache[gid]!;

  final raw = gid & 0x1FFFFFFF; // Clear flip bits
  Tileset? best; // The best match so far
  for (final ts in tilesets) {
    // Iterate through all tilesets
    if (ts.firstGid! <= raw) {
      // If this tileset could contain the gid
      if (best == null || ts.firstGid! > best.firstGid!) {
        best = ts; // Update best if it's a better match
      }
    }
  }
  if (best == null) {
    throw StateError('No tileset found for gid $gid (raw $raw)');
  }
  _tilesetCache[gid] = best;
  return best;
}

final _tilesetImageCache = <Tileset, Image>{};
FutureOr<Image?> getImageFromTileset(Tileset tileset) async {
  if (tileset.image?.source == null) return null;

  Image? cacheResult = _tilesetImageCache[tileset];

  if (cacheResult != null) {
    return cacheResult;
  }
  Image? calculatedResult = await getImageFromTilesetPath(
    tileset.image!.source!,
  );

  if (calculatedResult != null) _tilesetImageCache[tileset] = calculatedResult;

  return calculatedResult;
}

Future<Image?> getImageFromTilesetPath(String tilesetPath) async {
  if (!Flame.images.containsKey(tilesetPath)) {
    return await Flame.images.load(tilesetPath);
  } else {
    return Flame.images.fromCache(tilesetPath);
  }
}

final _normalTilesetImageCache = <Tileset, Image>{};
FutureOr<Image?> getNormalImageFromTileset(Tileset tileset) async {
  if (tileset.image?.source == null) return null;

  Image? cacheResult = _normalTilesetImageCache[tileset];

  if (cacheResult != null) {
    return cacheResult;
  }

  final String normalMapPath =
      "${RegExp("../images/([A-Za-z_0-9/]+).png").firstMatch(tileset.image!.source!)!.group(1)!}_normalMap.png";

  Image? calculatedResult = await getImageFromTilesetPath(normalMapPath);

  if (calculatedResult != null) {
    _normalTilesetImageCache[tileset] = calculatedResult;
  }

  return calculatedResult;
}

final _spriteImageCache = <Sprite, Image>{};
Future<Image> getTileFromTilesetToImage(Sprite sprite) async {
  Image? cacheResult = _spriteImageCache[sprite];
  if (cacheResult != null) return cacheResult;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  sprite.render(canvas);

  final picture = recorder.endRecording();
  final img = await picture.toImage(tilesize.x.toInt(), tilesize.y.toInt());
  _spriteImageCache[sprite] = img;
  return img;
}
