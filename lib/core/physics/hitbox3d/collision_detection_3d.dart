import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/math/ray3.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/util/raycasting_3d.dart';

import 'broadphase/broadphase_3d.dart';
import 'hitbox3d.dart';

/// [CollisionDetection] is the foundation of the collision detection system in
/// Flame.
///
/// If the [HasCollisionDetection] mixin is added to the game, [run] is called
/// every tick to check for collisions.
abstract class CollisionDetection3D<
T extends Hitbox3D<T>, B extends Broadphase3D<T>> {

  B broadphase;

  List<T> get items => broadphase.items;
  final _lastPotentials = <CollisionProspect<T>>[];
  final collisionsCompletedNotifier = CollisionDetectionCompletionNotifier();

  CollisionDetection3D({required this.broadphase});

  void add(T item) => broadphase.add(item);

  void addAll(Iterable<T> items) => items.forEach(add);

  /// Removes the [item] from the collision detection, if you just want to
  /// temporarily inactivate it you can set
  /// `collisionType = CollisionType.inactive;` instead.
  void remove(T item) => broadphase.remove(item);

  /// Removes all [items] from the collision detection, see [remove].
  void removeAll(Iterable<T> items) => broadphase.removeAll(items);

  /// Run collision detection for the current state of [items].
  void run() {
    broadphase.update();
    final potentials = broadphase.query();
    final hashes = Set.unmodifiable(potentials.map((p) => p.hash));

    for (final potential in potentials) {
      final itemA = potential.a;
      final itemB = potential.b;

      if (itemA.possiblyIntersects(itemB)) {
        final intersectionPoints = intersections(itemA, itemB);
        if (intersectionPoints.isNotEmpty) {
          if (!itemA.collidingWith(itemB)) {
            handleCollisionStart(intersectionPoints, itemA, itemB);
          }
          handleCollision(intersectionPoints, itemA, itemB);
          print("       --->  collision!");
        } else if (itemA.collidingWith(itemB)) {
          handleCollisionEnd(itemA, itemB);
        }
      } else if (itemA.collidingWith(itemB)) {
        handleCollisionEnd(itemA, itemB);
      }
    }

    //print("potentials: $potentials");

    // Handles callbacks for an ended collision that the broadphase didn't
    // report as a potential collision anymore.
    for (final prospect in _lastPotentials) {
      if (!hashes.contains(prospect.hash) &&
          prospect.a.collidingWith(prospect.b)) {
        handleCollisionEnd(prospect.a, prospect.b);
      }
    }

    // Let all listeners know that the collision detection step has completed
    collisionsCompletedNotifier.notifyListeners();
  }

  /// Check what the intersection points of two items are,
  /// returns an empty list if there are no intersections.
  Set<Vector3> intersections(T itemA, T itemB);

  void handleCollisionStart(Set<Vector3> intersectionPoints, T itemA, T itemB);

  void handleCollision(Set<Vector3> intersectionPoints, T itemA, T itemB);

  void handleCollisionEnd(T itemA, T itemB);

  /// Returns the first hitbox that the given [ray] hits and the associated
  /// intersection information; or null if the ray doesn't hit any hitbox.
  ///
  /// [maxDistance] can be provided to limit the raycast to only return hits
  /// within this distance from the ray origin.
  ///
  /// You can provide a [hitboxFilter] callback to define which hitboxes
  /// to consider and which to ignore. This callback will be called with
  /// every prospective hitbox, and only if the callback returns `true`
  /// will the hitbox be considered. Otherwise, the ray will go straight
  /// through it. One common use case is ignoring the component that is
  /// shooting the ray.
  ///
  /// If you have a list of hitboxes to ignore in advance,
  /// you can provide them via the [ignoreHitboxes] argument.
  ///
  /// If [out] is provided that object will be modified and returned with the
  /// result.
  RaycastResult3D<T>? raycast(
      Ray3 ray, {
        double? maxDistance,
        bool Function(T candidate)? hitboxFilter,
        List<T>? ignoreHitboxes,
        RaycastResult3D<T>? out,
      });

  /// Casts rays uniformly between [startAngle] to [startAngle]+[sweepAngle]
  /// from the given [origin] and returns all hitboxes and intersection points
  /// the rays hit.
  /// [numberOfRays] is the number of rays that should be casted.
  ///
  /// [maxDistance] can be provided to limit the raycasts to only return hits
  /// within this distance from the ray origin.
  ///
  /// If the [rays] argument is provided its [Ray3]s are populated with the rays
  /// needed to perform the operation.
  /// If there are less objects in [rays] than the operation requires, the
  /// missing [Ray3] objects will be created and added to [rays].
  ///
  /// You can provide a [hitboxFilter] callback to define which hitboxes
  /// to consider and which to ignore. This callback will be called with
  /// every prospective hitbox, and only if the callback returns `true`
  /// will the hitbox be considered. Otherwise, the ray will go straight
  /// through it. One common use case is ignoring the component that is
  /// shooting the ray.
  ///
  /// If you have a list of hitboxes to ignore in advance,
  /// you can provide them via the [ignoreHitboxes] argument.
  ///
  /// If [out] is provided the [RaycastResult3D]s in that list be modified and
  /// returned with the result. If there are less objects in [out] than the
  /// result requires, the missing [RaycastResult3D] objects will be created.
  List<RaycastResult3D<T>> raycastAll(
      Vector3 origin, {
        required int numberOfRays,
        Vector2? startAngle,
        Vector2? sweepAngle,
        double? maxDistance,
        List<Ray3>? rays,
        bool Function(T candidate)? hitboxFilter,
        List<T>? ignoreHitboxes,
        List<RaycastResult3D<T>>? out,
      });

  /// Follows the ray and its reflections until [maxDepth] is reached and then
  /// returns all hitboxes, intersection points, normals and reflection rays
  /// (bundled in a list of [RaycastResult3D]s) from where the ray hits.
  ///
  /// [maxDepth] is how many times the ray should collide before returning a
  /// result, defaults to 10.
  ///
  /// You can provide a [hitboxFilter] callback to define which hitboxes
  /// to consider and which to ignore. This callback will be called with
  /// every prospective hitbox, and only if the callback returns `true`
  /// will the hitbox be considered. Otherwise, the ray will go straight
  /// through it. One common use case is ignoring the component that is
  /// shooting the ray.
  ///
  /// If you have a list of hitboxes to ignore in advance,
  /// you can provide them via the [ignoreHitboxes] argument.
  ///
  /// If [out] is provided the [RaycastResult3D]s in that list be modified and
  /// returned with the result. If there are less objects in [out] than the
  /// result requires, the missing [RaycastResult3D] objects will be created.
  Iterable<RaycastResult3D<T>> raytrace(
      Ray3 ray, {
        int maxDepth = 10,
        bool Function(T candidate)? hitboxFilter,
        List<T>? ignoreHitboxes,
        List<RaycastResult3D<T>>? out,
      });
}