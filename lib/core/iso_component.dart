import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/rendering.dart';
import 'package:flutter/material.dart' hide Matrix4, TextStyle;
import 'package:mpg_achievements_app/core/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/core/misc/transform3d_decorator.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import 'math/iso_anchor.dart';
import 'math/notifying_vector_3.dart';
import 'math/transform3d.dart';

class IsoPositionComponent extends Component with IsometricRenderable implements IsoAnchorProvider, IsoSizeProvider, IsoPositionProvider, IsoScaleProvider {
  Transform3D transform;
  Anchor3D _anchor;

  late Decorator decorator;

  IsoPositionComponent({
    super.children,
    super.priority,
    super.key,
    Vector3? position,
    required Vector3 size,
    Vector3? scale,
    Anchor3D? anchor,
  }) : transform = Transform3D(),
      _anchor = anchor ?? Anchor3D.bottomLeftLeft, super() {
    this.position = position ?? Vector3.zero();
    this.size = size;

    _size.addListener(_onModifiedSizeOrAnchor);
    _onModifiedSizeOrAnchor();
  }

  @override
  @mustCallSuper
  FutureOr<void> onMount(){
    super.onMount();
    decorator = IsometricDecorator(transform);
  }

  Matrix4 get transformMatrix => transform.transformMatrix;

  @override
  @mustCallSuper
  void render(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    super.render(canvas);
  }

  @override
  void renderTree(Canvas canvas, [Canvas? normalCanvas, Paint Function()? getNormalPaint]) {
    decorator.applyChain((p0) {
      final List<Component> allComponents = [
        this, ...children
      ];

      allComponents.sort((a, b) => a.priority.compareTo(b.priority)); //todo sort via depth and override childrenFactory to auto sort children

      for (var element in allComponents) {
        if (element == this && element is IsoPositionComponent) {
          element.render(canvas, normalCanvas, getNormalPaint);
          if (debugMode) {
            renderDebugMode(canvas);
          }
        } else if(element is IsoPositionComponent){
          element.renderTree(canvas, normalCanvas, getNormalPaint);
        } else {
          element.renderTree(canvas);
        }
      }
    }, canvas);
  }

  @override
  Vector3 get gridFeetPos => positionOfAnchor(Anchor3D.bottomLeftLeft);

  @override
  Vector3 get gridHeadPos => positionOfAnchor(Anchor3D.topRightRight);

  @override
  Anchor3D get anchor => _anchor;

  @override
  set anchor(Anchor3D newAnchor ) {
    _anchor = newAnchor;
    _onModifiedSizeOrAnchor();
  }

  final NotifyingVector3 _size = NotifyingVector3.all(1);

  @override
  NotifyingVector3 get size => _size;
  Vector3 get scaledSize => Vector3.copy(size)..multiply(scale);

  @override
  set size(Vector3 newSize) {
    _size.setFrom(newSize);
    _onModifiedSizeOrAnchor();
  }

  double get width => _size.x;
  double get height => _size.y;
  double get depth => _size.z;

  late Vector2 _size2D;

  Vector2 get size2D => _size2D;

  @override
  Vector3 get scale => transform.scale;

  @override
  set scale(Vector3 newScale) {
    transform.scale.setFrom(newScale);
  }

  @override
  Vector3 get position => transform.position;

  Vector2 get screenPos => toWorldPos(absolutePosition);

  double get x => position.x;
  set x(double newX) => position = Vector3(newX, position.y, position.z);

  double get y => position.y;
  set y(double newY) => position = Vector3(position.x, newY, position.z);

  double get z => position.z;
  set z(double newZ) => position = Vector3(position.x, position.y, newZ);

  @override
  set position(Vector3 newPosition) {
    transform.position = newPosition;
  }

  /// Convert local coordinates of a point [point] inside the component
  /// into the parent's coordinate space.
  Vector3 positionOf(Vector3 point) => transform.localToGlobal(point);

  /// Similar to [positionOf()], but applies to any anchor point within
  /// the component.
  Vector3 positionOfAnchor(Anchor3D anchor) =>
    positionOf(Vector3(anchor.x * scaledSize.x, anchor.y * scaledSize.y, anchor.z * scaledSize.z));

  /// Convert local coordinates of a point [point] inside the component
  /// into the global (world) coordinate space.
  Vector3 absolutePositionOf(Vector3 point) {
    var parentPoint = positionOf(point);
    var ancestor = parent;
    while (ancestor != null) {
      if (ancestor is IsoPositionComponent) {
        parentPoint = ancestor.positionOf(parentPoint);
      }
      ancestor = ancestor.parent;
    }
    return parentPoint;
  }

  /// Similar to [absolutePositionOf()], but applies to any anchor
  /// point within the component.
  Vector3 absolutePositionOfAnchor(Anchor3D anchor) =>
      absolutePositionOf(Vector3(anchor.x * scaledSize.x, anchor.y * scaledSize.y, anchor.z * scaledSize.z));

  /// Transform [point] from the parent's coordinate space into the local
  /// coordinates. This function is the inverse of [positionOf()].
  Vector3 toLocal(Vector3 point) => transform.globalToLocal(point);

  /// Transform [point] from the global (world) coordinate space into the
  /// local coordinates. This function is the inverse of
  /// [absolutePositionOf()].
  ///
  /// This can be used, for example, to detect whether a specific point
  /// on the screen lies within this [PositionComponent], and where
  /// exactly it hits.
  Vector3 absoluteToLocal(Vector3 point) {
    var c = parent;
    while (c != null) {
      if (c is IsoPositionComponent) {
        return toLocal(c.absoluteToLocal(point));
      }
      c = c.parent;
    }
    return toLocal(point);
  }

  /// The position of the center of the component's bounding rectangle
  /// in the parent's coordinates.
  Vector3 get center => positionOfAnchor(Anchor3D.center);
  set center(Vector3 point) {
    position += point - center;
  }

  /// The [anchor]'s position in absolute (world) coordinates.
  Vector3 get absolutePosition => absolutePositionOfAnchor(_anchor);

  /// The absolute bottom left left position regardless of whether it is a child or not.
  Vector3 get absoluteBottomLeftLeftPosition =>
      absolutePositionOfAnchor(Anchor3D.bottomLeftLeft);

  /// The absolute center of the component.
  Vector3 get absoluteCenter => absolutePositionOfAnchor(Anchor3D.center);


  void _onModifiedSizeOrAnchor() {
    final Vector3 scaledSize = this.scaledSize;
    transform.offset = -Vector3(_anchor.x * scaledSize.x, _anchor.y * scaledSize.y, _anchor.z * scaledSize.z);
    _size2D = projectedBounds(scaledSize.clone(), tilesize.x, tilesize.y, tilesize.z);
  }
}

abstract class IsoPositionProvider implements ReadOnlyIsoPositionProvider{
  set position(Vector3 newPosition);
}
abstract class IsoSizeProvider implements ReadOnlyIsoSizeProvider{
  set size(Vector3 newSize);
}
abstract class IsoScaleProvider implements ReadOnlyIsoScaleProvider{
  set scale(Vector3 newScale);
}

abstract class IsoAnchorProvider {
  set anchor(Anchor3D newAnchor);
  Anchor3D get anchor;
}

abstract class ReadOnlyIsoSizeProvider{
  Vector3 get size;
}
abstract class ReadOnlyIsoPositionProvider{
  Vector3 get position;
}
abstract class ReadOnlyIsoScaleProvider{
  Vector3 get scale;
}