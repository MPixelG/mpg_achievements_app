import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/core/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/core/level/rendering/chunk.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

abstract class IsoPositionComponent extends PositionComponent with IsometricRenderable{
  Vector3 isoPosition = Vector3.zero();

  Vector3 get isoPositionAbsolute {
    if(parent is IsoPositionComponent){
      return isoPosition + (parent as IsoPositionComponent).isoPositionAbsolute;
    }
    return isoPosition;
  }

  IsoPositionComponent({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.nativeAngle = 0,
    super.anchor,
    super.children,
    super.priority,
    super.key,
    Vector3? isoPosition
  }) : super(){
    this.isoPosition = isoPosition ?? Vector3.zero();
  }



  @Deprecated('please use isoPosition. if you really need it, use position2D')
  @override
  NotifyingVector2 get position => super.position;


  NotifyingVector2 get position2D => super.position;
  set position2D(Vector2 value) {
    super.position = value;
  }


  @Deprecated('please use isoPosition. if you really need it, use position2D')
  @override
  set position(Vector2 value) {
    super.position = value;
  }

  Vector2 get parentSize {
    if(parent is PositionComponent){
      return (parent as PositionComponent).size;
    } else {
      return Chunk.worldSize;
    }
  }

  @override
  void update(double dt) {
    transform.position = anchor.toVector2() + toWorldPos(isoPosition,parentSize.x) + Vector2(isFlippedHorizontally ? size.x : 0, 0);
  }

  @override
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas);
  }

  @override
  void renderTree(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    decorator.applyChain((p0) {
      List<Component> allComponents = [];

      allComponents.addAll([
        this, ...children
      ]);

      allComponents.sort((a, b) => a.priority.compareTo(b.priority)); //todo sort via depth

      for (var element in allComponents) {
        if (element == this && element is IsoPositionComponent) {
          element.render(canvas, normalCanvas, getNormalPaint);
          if (debugMode) {
            renderDebugMode(canvas);
          }
        } else if(element is IsoPositionComponent){
          element.renderTree(canvas, normalCanvas, getNormalPaint);
        }
      }
    }, canvas);
  }

  @override
  Vector3 get gridFeetPos => isoPosition;

  @override
  Vector3 get gridHeadPos => isoPosition + isoSize;

  Vector3 get isoSize;
}