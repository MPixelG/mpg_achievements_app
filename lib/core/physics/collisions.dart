import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/level_components/entity/game_character.dart';
import 'package:mpg_achievements_app/core/iso_component.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/iso_collision_callbacks.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

/// Mixin for adding collision detection behavior to a component.
/// Requires implementing methods to provide hitbox, position, velocity, etc
mixin HasCollisions
    on GameCharacter,
        IsoCollisionCallbacks,
        HasGameReference<PixelAdventure>{
  set debugNoClipMode(bool val) => _debugNoClipMode = val;
  bool get debugNoClipMode => _debugNoClipMode;
  bool _debugNoClipMode = true;
  
  bool colliding = false;
  @override
  void onCollision(Set<Vector3> intersectionPoints, IsoPositionComponent other){
    colliding = true;
    super.onCollision(intersectionPoints, other);
  }
  @override
  void onCollisionEnd(IsoPositionComponent other){
    colliding = false;
    super.onCollisionEnd(other);
  }
  
  Vector3 directionTo(Vector3 pos1, Vector3 pos2){
    final Vector3 diff = pos2-pos1;
    return diff.normalized();
  }
  
  Vector3 lastSafePosition = Vector3.zero();
  bool justGotUnstuck = false;
  @override
  void update(double dt) {
    if(colliding) {
      position.setFrom(lastSafePosition);
      velocity.y = 0.6;
    } else if(justGotUnstuck) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 20), () {
          if(!colliding){
            lastSafePosition = position.clone();
            justGotUnstuck = false;
          }
        });
        return justGotUnstuck;
      });
    } else {
      lastSafePosition = position.clone();
    }
    super.update(dt);
  }

}
