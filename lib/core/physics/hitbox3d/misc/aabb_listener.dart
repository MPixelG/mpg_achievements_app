import '../hitbox3d.dart';

abstract interface class HitboxAabb3Listener<T extends Hitbox3D<T>> {
  void onAabbChange(T hitbox);
}

