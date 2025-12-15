import 'package:mpg_achievements_app/isometric/src/core/physics/hitbox3d/hitbox3d.dart';

abstract interface class HitboxAabb3Listener<T extends Hitbox3D<T>> {
  void onAabbChange(T hitbox);
}