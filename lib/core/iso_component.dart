import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

class IsoPositionComponent extends PositionComponent {
  Vector3 isoPosition = Vector3.zero();
  Vector3 velocity = Vector3.zero();


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
  }) : super();



  @Deprecated('please use the isoPosition to avoid problems')
  @override
  NotifyingVector2 get position => super.position;

  @Deprecated('please use the isoPosition to avoid problems')
  @override
  set position(Vector2 value) {
    super.position = value;
  }


  static const double movementSpeed = 0.3;
  @override
  void update(double dt) {
    super.update(dt);
    velocity *= pow(0.05, dt).toDouble();
    print("velocity: $velocity");

    isoPosition += velocity * dt * movementSpeed;

    transform.position = isoToScreen(isoPosition) + Vector2((scale.x < 0) ? size.x : 0, 0);
  }
}