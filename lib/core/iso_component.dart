import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

class IsoPositionComponent extends PositionComponent {
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
  }) : super();



  @Deprecated('please use the isoPosition to avoid problems')
  @override
  NotifyingVector2 get position => super.position;

  @Deprecated('please use the isoPosition to avoid problems')
  @override
  set position(Vector2 value) {
    super.position = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    transform.position = isoToScreen(isoPosition) + Vector2((scale.x < 0) ? size.x : 0, 0);
  }
}