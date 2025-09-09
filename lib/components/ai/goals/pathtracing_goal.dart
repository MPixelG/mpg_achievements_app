import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:mpg_achievements_app/components/ai/goals/goal.dart';
import 'package:mpg_achievements_app/components/physics/collision_block.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import '../../physics/movement.dart';
import '../../physics/collisions.dart';
import '../../entity/player.dart';

class PathtracingGoal extends Goal{


  BasicMovement get movement => parent!.parent as BasicMovement;
  PixelAdventure get game => (parent!.parent as HasGameReference<PixelAdventure>).game;
  Vector2 get center => (parent!.parent as PositionComponent).center;
  Vector2 get absolutePosition => (parent!.parent as PositionComponent).absolutePosition;
  ShapeHitbox get hitbox => (parent!.parent as HasCollisions).hitbox;


  double time = 0;
  double timeSinceLastUpdate = 1;

  Ray2? ray;
  Ray2? reflection;
  late Vector2 rayOriginPoint = absolutePosition;
  final Vector2 rayDirection = Vector2(1, 0);

  static const numberOfRays = 36;
  final List<Ray2> rays = [];
  final List<RaycastResult<ShapeHitbox>> results = [];
  late List<RaycastResult<ShapeHitbox>> lastResults = [];

  PathtracingGoal(super.prequisite, super.goalPriority);



  @override
  void updateGoal(double dt){
    time += dt; //increase the timers
    timeSinceLastUpdate += dt;

    // if (time < 1 && !(timeSinceLastUpdate < 2 && time > 0.5))
    //   return; //if the countdown isnt done and the last intersection with sth movable is more than a second ago, we return
    time = 0; //reset the timer for the next ray

    rayOriginPoint =
        center; //use the center of the player as the start of the raycast. note that this has to be an absolute position because we calculate it from the game, not from this character

    lastResults = results
        .toList(); //update the last results and make sure not to create a reference
    results.clear(); //clear all the values

    game.collisionDetection.raycastAll(
      //raycast rays in all different directions and deposit the results in the results Set
      startAngle: -90,
      rayOriginPoint,
      numberOfRays: timeSinceLastUpdate < 1 ? numberOfRays * 3 : numberOfRays,
      rays: rays,
      out: results,
      ignoreHitboxes: [hitbox],
      hitboxFilter: (candidate) {


        if(candidate.parent is CollisionBlock){
          return !(candidate.parent as CollisionBlock).isLadder;
        }
        return candidate.parent is Player;


      },
    );

    if (checkIntersectionChange(results, lastResults)) {
      //if sth changed, we reset the timer since the last intersection with sth movable
      timeSinceLastUpdate = 0; //reset the timer
    }


    double shortestPlayerDistance = double.infinity;
    Vector2? shortestPlayerDistancePos;

    for (var element in results) {
      if(element.hitbox != null && element.hitbox!.parent is Player){
        if(element.intersectionPoint!.distanceTo(rayOriginPoint) < shortestPlayerDistance) {shortestPlayerDistance = element.intersectionPoint!.distanceTo(rayOriginPoint); shortestPlayerDistancePos = element.intersectionPoint!;}
        continue;
      }
    }


    attributes!.attributes["playerPositions"] = results;
    if(shortestPlayerDistancePos != null) attributes!.attributes["nearestPlayerPosition"] = shortestPlayerDistancePos;
  }


  bool checkIntersectionChange<T>(
      List<RaycastResult> currentRayIntersections,
      List<RaycastResult> lastRayIntersections,) {

    if (currentRayIntersections.length != lastRayIntersections.length) {
      return false; //if the lists dont have the same length, they cant be equal
    }

    for (int i = 0; i < currentRayIntersections.length; i++) {
      //we iterate over every ray

      Hitbox<dynamic>? hitbox1 = currentRayIntersections
          .elementAt(i)
          .hitbox; //the hitbox of the ray intersection
      Hitbox<dynamic>? hitbox2 = lastRayIntersections.elementAt(i).hitbox;

      PositionComponent? parent1 = getParentAsPositionComponent(
        hitbox1,
      ); //we get the component of the hitbox the ray collided with. if it cant store a position its null
      PositionComponent? parent2 = getParentAsPositionComponent(hitbox2);

      if (parent1 == null || parent2 == null) {
        continue; //if this or the last intersection has no position (bc its outside of the world) we continue with the next ray
      }
      if (parent1 is! BasicMovement) {
        continue; //if the new ray intersects with sth unmovable then we can continue with the next ray
      }

      if ((currentRayIntersections.elementAt(i).intersectionPoint?..round()) !=
          (lastRayIntersections.elementAt(i).intersectionPoint?..round())) {
        //we check if the current ray intersection point is at a different pos as the last one
        return true; //return that theres sth movable, that moved
      }
    }

    return false; //if we went through all of the rays and not a single one changed, we return that nothing has changed
  }

  PositionComponent? getParentAsPositionComponent(Hitbox<dynamic>? hitbox) {
    if (hitbox == null) return null;

    if (hitbox is! ShapeHitbox) return null;

    Component? parent = hitbox.parent;

    if (parent == null || parent is! PositionComponent) {
      return null;
    }

    return parent;
  }

}