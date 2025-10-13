import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:mpg_achievements_app/core/level/rendering/chunk.dart';
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



  @Deprecated('please use isoPosition')
  @override
  NotifyingVector2 get position => super.position;


  @Deprecated('please use isoPosition')
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
  void renderTree(Canvas canvas){
    decorator.applyChain((p0) {

      List<Component> allComponents = [];

      allComponents.addAll([
        this, ...children
      ]);

      allComponents.sort((a, b) => a.priority.compareTo(b.priority)); //todo sort via depth

      for (var element in allComponents) {
        if (element == this) {
          element.render(canvas);
        } else {
          element.renderTree(canvas);
        }
      }
    }, canvas);
  }

}