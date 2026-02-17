
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/shapes/shape_hitbox3d.dart';
import 'broadphase/broadphase_3d.dart';
import 'broadphase/chunking_collision_detection.dart';
import 'collision_detection_3d.dart';
import 'hitbox3d.dart';

/// Keeps track of all the [ShapeHitbox3D]s in the component's tree and initiates
/// collision detection every tick.
///
/// Hitboxes are only part of the collision detection performed by its closest
/// parent with the [HasCollisionDetection3D] mixin, if there are multiple nested
/// classes that has [HasCollisionDetection3D].

//add mixin to game class for implementation
mixin HasCollisionDetection3D on Component {
  late CollisionDetection3D<ShapeHitbox3D, Broadphase3D<ShapeHitbox3D>> _collisionDetection;
  bool _isInitialized = false;

  CollisionDetection3D<ShapeHitbox3D, Broadphase3D<ShapeHitbox3D>> get collisionDetection {
    if (!_isInitialized) {
      // Initialize the specific implementation here
      _collisionDetection = ChunkingCollisionDetection3D();
      _isInitialized = true;
    }
    return _collisionDetection;
  }

  set collisionDetection(CollisionDetection3D<ShapeHitbox3D, Broadphase3D<ShapeHitbox3D>> cd) {

    if (_isInitialized) {
      cd.addAll(_collisionDetection.items);
    }
    _collisionDetection = cd;
    _isInitialized = true;
  }

  @override
  void update(double dt) {
    if (_isInitialized) {
      _collisionDetection.run();
    }
    super.update(dt);
  }
}

/// This mixin is useful if you have written your own collision detection which
/// isn't operating on [ShapeHitbox] since you can have any hitbox here.
///
/// Do note that [collisionDetection] has to be initialized before the game
/// starts the update loop for the collision detection to work.
mixin HasGenericCollisionDetection<T extends Hitbox3D<T>, B extends Broadphase3D<T>>
on Component {
  CollisionDetection3D<T, B>? _collisionDetection;
  CollisionDetection3D<T, B> get collisionDetection => _collisionDetection!;

  set collisionDetection(CollisionDetection3D<T, B> cd) {
    if (_collisionDetection != null) {
      cd.addAll(_collisionDetection!.items);
    }
    _collisionDetection = cd;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _collisionDetection?.run();
  }
}
