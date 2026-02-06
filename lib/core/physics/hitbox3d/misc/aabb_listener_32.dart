import '../hitbox3d_32.dart';

abstract interface class HitboxAabb3Listener<T extends Hitbox3D<T>> {
  void onAabbChange(T hitbox);
}

