import 'dart:async';

import 'package:flame/components.dart' hide Vector3, Matrix4, Vector2;
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/cupertino.dart' hide Matrix4;
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:mpg_achievements_app/3d/src/state_management/providers/game_state_provider.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/iso_anchor.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/notifying_vector_3.dart';
import 'package:mpg_achievements_app/isometric/src/core/math/transform3d.dart';
import 'package:mpg_achievements_app/util/utils.dart';
import 'package:vector_math/vector_math_64.dart';

class PositionComponent3d extends Component with HasGameReference<PixelAdventure3D>, RiverpodComponentMixin implements Anchor3DProvider, Size3DProvider, Position3DProvider, Scale3DProvider, Rotation3DProvider {
  Transform3D transform;
  Anchor3D _anchor;


  PositionComponent3d({
    super.children,
    super.priority,
    super.key,
    Vector3? position,
    required Vector3 size,
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
  }

  Matrix4 get transformMatrix => transform.transformMatrix;

  @Deprecated("dont use the 2d render methods!")
  @override
  @mustCallSuper
  void render(Canvas canvas) {
    super.render(canvas);
  }

  @Deprecated("dont use the 2d render methods!")
  @override
  void renderTree(Canvas canvas){}

  Vector3 get gridFeetPos => absolutePositionOfAnchor(Anchor3D.bottomCenter);
  Vector3 get gridHeadPos => absolutePositionOfAnchor(Anchor3D.topCenter);

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

  @override
  Vector3 get scale => transform.scale;

  @override
  set scale(Vector3 newScale) {
    transform.scale.setFrom(newScale);
  }

  @override
  Vector3 get position => transform.position;

  Future<Vector3?> get screenPos async => worldToScreen(worldPosition: position, viewMatrix: await game.camera3D!.thermionCamera.getViewMatrix(), projectionMatrix: await game.camera3D!.thermionCamera.getProjectionMatrix(), screenSize: ref.read(gameProvider).size
  ); //todo make generic getter for size in game

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
      if (ancestor is PositionComponent3d) {
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
      if (c is PositionComponent3d) {
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
  }

  @override
  double get rotationX => transform.angleRoll;

  @override
  double get rotationY => transform.anglePitch;

  @override
  double get rotationZ => transform.angleYaw;


  @override
  set rotationX(double newRotationX) => transform.angleRoll = newRotationX;
  @override
  set rotationY(double newRotationY) => transform.anglePitch = newRotationY;
  @override
  set rotationZ(double newRotationZ) => transform.angleYaw = newRotationZ;
  

  void setRotation({double? x, double? y, double? z}) {
    final Matrix4 rotationMatrix = Matrix4.identity();

    if (y != null) {
      rotationMatrix.multiply(Matrix4.rotationY(y));
    }
    if (x != null) {
      rotationMatrix.multiply(Matrix4.rotationX(x));
    }
    if (z != null) {
      rotationMatrix.multiply(Matrix4.rotationZ(z));
    }

    transformMatrix.setRotation(rotationMatrix.getRotation());
  }


}

abstract class Position3DProvider implements ReadOnlyPosition3DProvider{
  set position(Vector3 newPosition);
}
abstract class Size3DProvider implements ReadOnlySize3DProvider{
  set size(Vector3 newSize);
}
abstract class Scale3DProvider implements ReadOnlyScale3DProvider{
  set scale(Vector3 newScale);
}
abstract class Anchor3DProvider {
  set anchor(Anchor3D newAnchor);
  Anchor3D get anchor;
}
abstract class Rotation3DProvider implements ReadOnlyRotation3DProvider{
  set rotationX(double newRotationX);
  set rotationY(double newRotationY);
  set rotationZ(double newRotationZ);
}

abstract class ReadOnlySize3DProvider{
  Vector3 get size;
}
abstract class ReadOnlyPosition3DProvider{
  Vector3 get position;
}
abstract class ReadOnlyScale3DProvider{
  Vector3 get scale;
}
abstract class ReadOnlyRotation3DProvider{
  double get rotationX;
  double get rotationY;
  double get rotationZ;
}