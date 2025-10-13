
import 'dart:ui';

import 'package:mpg_achievements_app/core/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';
import 'package:mpg_achievements_app/util/texture_utils.dart';
import 'package:vector_math/vector_math.dart';

import 'game_sprite.dart';

class ChunkTile with IsometricRenderable {
  final int gid;
  final int localX;
  final int localY;
  final int worldX;
  final int worldY;
  final int z;
  int zAdjustPos;

  Vector3 get posWorld => Vector3(worldX.toDouble(), worldY.toDouble(), z.toDouble());
  Vector3 get posLocal => Vector3(localX.toDouble(), localY.toDouble(), z.toDouble());

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
  Vector3 get gridHeadPos => gridFeetPos;

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
