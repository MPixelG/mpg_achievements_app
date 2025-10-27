
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
  final int localZ;
  final int worldX;
  final int worldZ;
  final int y;
  int yAdjustPos;

  Vector3 get posWorld => Vector3(worldX.toDouble(), y.toDouble(), worldZ.toDouble());
  Vector3 get posLocal => Vector3(localX.toDouble(), y.toDouble(), localZ.toDouble());

  ChunkTile(
      this.gid,
      this.localX,
      this.localZ,
      this.worldX,
      this.worldZ,
      this.y,
      this.yAdjustPos,
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

  final Paint renderPaint = Paint()..isAntiAlias = false..filterQuality = FilterQuality.none;
  @override
  void renderTree(Canvas albedoCanvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    Vector2 position = toWorldPos(posWorld) - Vector2(tilesize.x / 2, 0);
    if(normalCanvas != null) {
      cachedSprite.normalAndDepth?.render(
        normalCanvas,
        position: position,
        overridePaint: getNormalPaint!(),
      );
    }
    cachedSprite.albedo.render(albedoCanvas, position: position, overridePaint: renderPaint);
  }
}