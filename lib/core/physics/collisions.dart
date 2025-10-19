import 'dart:async';
import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/components/level_components/entity/game_character.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';

import 'collision_block.dart';

/// Mixin for adding collision detection behavior to a component.
/// Requires implementing methods to provide hitbox, position, velocity, etc
mixin HasCollisions
    on
        GameCharacter,
        CollisionCallbacks,
        HasGameReference<PixelAdventure>{
  void setDebugNoClipMode(bool val) => _debugNoClipMode = val;

  bool _debugNoClipMode = false;

  @override
  FutureOr<void> onLoad() {
    // hitbox = IsometricHitbox(Vector2.all(1), Vector3.zero());
    // hitbox!.position = Vector2(0, 16);
    //
    // add(hitbox!);
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is CollisionBlock &&
        !_debugNoClipMode) {
      velocity = Vector3.zero();
      gridPos = lastSafePosition;
      return;
    }
    super.onCollision(intersectionPoints, other);
  }

  Vector2 lastSafePosition = Vector2.zero();
  @override
  void update(double dt) {
    if (!game.gameWorld.checkCollisionAt(gridPos.clone()..floor())) {
      lastSafePosition = gridPos;
    } else {}
    super.update(dt);
  }

  bool isHitboxInside(Hitbox? hitboxA, Hitbox? hitboxB) {
    if (hitboxB == null || hitboxA == null) return false;
    return hitboxB.aabb
        .toRect()
        .translate(0.8, 0.8)
        .overlaps(hitboxA.aabb.toRect());
  }
}
