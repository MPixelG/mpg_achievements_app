

import 'package:flutter/cupertino.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/util/type_utils.dart';
import 'package:vector_math/vector_math.dart';
import 'isoCollisionCallbacks.dart';

/// This mixin can be used if you want to pass the [CollisionCallbacks] to the
/// next ancestor that can receive them. It can be used to group hitboxes
/// together on a component, that then is added to another component that also
/// cares about the collision events of the hitboxes.
mixin CollisionPassthrough on IsoCollisionCallbacks {
  /// The parent that the events should be passed on to.
  IsoCollisionCallbacks? passthroughParent;

  @override
  @mustCallSuper
  void onMount() {
    super.onMount();
    passthroughParent =
      ancestors().firstWhereOrNull(
            (c) => c is IsoCollisionCallbacks,
          )
      as IsoCollisionCallbacks?;
  }

  @override
  @mustCallSuper
  void onCollision(Set<Vector3> intersectionPoints, IsoPositionComponent other) {
    super.onCollision(intersectionPoints, other);
    passthroughParent?.onCollision(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionStart(
      Set<Vector3> intersectionPoints,
      IsoPositionComponent other,
      ) {
    super.onCollisionStart(intersectionPoints, other);
    passthroughParent?.onCollisionStart(intersectionPoints, other);
  }

  @override
  @mustCallSuper
  void onCollisionEnd(IsoPositionComponent other) {
    super.onCollisionEnd(other);
    passthroughParent?.onCollisionEnd(other);
  }
}
