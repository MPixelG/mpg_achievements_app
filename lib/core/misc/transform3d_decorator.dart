
import 'package:flame/extensions.dart';
import 'package:flame/rendering.dart';
import 'package:mpg_achievements_app/util/isometric_utils.dart';

import '../math/transform3d.dart';

/// [Transform3DDecorator] applies a translation/rotation/scale transform to
/// the canvas.
///
/// This decorator is used internally by the [PositionComponent].
class IsometricDecorator extends Decorator {
   IsometricDecorator([Transform3D? transform, Vector3 Function()? getOffset])
      : transform3d = transform ?? Transform3D();

   final Transform3D transform3d;

   @override
   void apply(void Function(Canvas) draw, Canvas canvas) {
     canvas.save();

     final posWithOffset = transform3d.position + transform3d.offset;
     final screenPos = toWorldPos(posWithOffset);

     canvas.translate(screenPos.x, screenPos.y);
     canvas.rotate(transform3d.angleRoll);
     canvas.scale(transform3d.scale.x, transform3d.scale.y);

     draw(canvas);

     canvas.restore();
   }
}
