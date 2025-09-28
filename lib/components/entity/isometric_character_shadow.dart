import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/entity/isometricPlayer.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import '../../core/level/isometric/isometric_renderable.dart';
import '../../core/level/isometric/isometric_tiled_component.dart';



class ShadowComponent extends PositionComponent implements IsometricRenderable {

 late Vector3 gridPos;
 final IsometricPlayer owner;

  ShadowComponent(this.gridPos, {required this.owner});


 @override
 void update(double dt) {
   super.update(dt);
   // Continuously update the shadow's grid position to match the owner's.
   // This ensures correct render sorting as the player moves.
   gridPos = owner.gridFeetPos;
 }



 @override
 void render(Canvas canvas) {
   super.render(canvas);
   // Convert the selected tile's grid coordinates into its center position in the isometric world.
   final tileW = tilesize.x;
   final tileH = tilesize.y;
   final halfTile = Vector2(tileW / 3, tileH / 6);


   // Define the four points
   final rect = Rect.fromLTRB(-halfTile.x, -halfTile.y, halfTile.x, halfTile.y);

   // Define a paint for the highlight.
   final highlightPaint = Paint()
     ..color = Colors.black38// Semi-transparent black
     ..style = PaintingStyle.fill;


   // Draw the oval inside the rectangle
   canvas.drawOval(rect, highlightPaint);
 }



  @override
  RenderCategory get renderCategory =>
      RenderCategory.characterEffect;

  @override
    Vector3 get gridFeetPos => gridPos;

  @override
  bool updatesNextFrame = false;


  @override
  bool dirty = false;

  @override
  Vector3 get gridHeadPos => throw UnimplementedError();

  @override
  void Function(Canvas canvas) get renderAlbedo => renderTree;

  @override
  void Function(Canvas canvas, Paint? overridePaint)? get renderNormal {
    return null;
  }

  @override
  void setDirty([bool value = true]) {
    dirty = value;
  }

}