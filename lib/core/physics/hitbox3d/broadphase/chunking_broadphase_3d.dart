
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/broadphase/broadphase_3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/hitbox3d.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/misc/aabb_listener.dart';

class ChunkingBroadphase3D<T extends Hitbox3D<T>> extends Broadphase3D<T> implements HitboxAabb3Listener<T>{
  ChunkingBroadphase3D();

  /// A map of hitbox IDs to their corresponding hitboxes.
  final Map<int, T> _hitboxes = {};
  final Map<Vector3, List<int>> _chunks = {};
  final Map<int, Set<Vector3>> _lastKnownChunks = {};

  static const double chunkSize = 4;

  @override
  List<T> get items => _hitboxes.values.toList();

  final _potentials = <CollisionProspect<T>>{};

  @override
  void add(T item) {
    _hitboxes[item.id] = item;

    Set<Vector3> chunks = _getChunksOfHitbox(item);

    for (var chunk in chunks) {
      _chunks[chunk] ??= [];
      _chunks[chunk]!.add(item.id);
    }
    item.addAabbListener(this);
    _lastKnownChunks[item.id] = chunks;
  }

  @override
  void remove(T item) {
    _hitboxes.remove(item.id);

    _getChunksOfHitbox(item).forEach((chunk) {
      _chunks[chunk]!.remove(item.id);
      if (_chunks[chunk]?.isEmpty ?? false) {
        _chunks.remove(chunk);
      }
    });
    item.removeAabbListener(this);
    _lastKnownChunks.remove(item.id);
  }

  void updateHitbox(T item) {
    final oldChunks = _lastKnownChunks[item.id];
    if (oldChunks == null) return;

    final newChunks = _getChunksOfHitbox(item);

    for (final chunk in oldChunks) {
      if (!newChunks.contains(chunk)) {
        _chunks[chunk]?.remove(item.id);
        if (_chunks[chunk]?.isEmpty ?? false) {
          _chunks.remove(chunk);
        }
      }
    }

    for (final chunk in newChunks) {
      if (!oldChunks.contains(chunk)) {
        _chunks[chunk] ??= [];
        _chunks[chunk]!.add(item.id);
      }
    }

    _lastKnownChunks[item.id] = newChunks;
  }

  @override
  void onAabbChange(T hitbox) {
    updateHitbox(hitbox);
    if(hitbox.id != 1) print("updated hitbox ${hitbox.id} to ${hitbox.aabb.min}!");
  }

  @override
  Iterable<CollisionProspect<T>> query() {

    _potentials.clear();
    for (final item in _hitboxes.values) {
      final itemChunks = _getChunksOfHitbox(item);

      //print("${item.id} is currently at ${item.aabb.min} - ${item.aabb.max}");

      for (final chunk in itemChunks) {
        final hitboxIdsInChunk = _chunks[chunk]!;

        for (final hitboxId in hitboxIdsInChunk) {
          final hitbox = _hitboxes[hitboxId]!;
          if (hitbox != item) {

            if (item.id < hitboxId){
              _potentials.add(CollisionProspect(item, hitbox));
            }
          }
        }
      }
    }
    _potentials.forEach((element) {
      //print("potential: ${element.a} - ${element.b}");
    });
    return _potentials;
  }


  Set<Vector3> _getChunksOfHitbox(Hitbox3D hitbox){
    Set<Vector3> occupiedChunks = {};

    Vector3 start = hitbox.aabb.min;
    Vector3 end = hitbox.aabb.max;


    int startX = (start.x / chunkSize).floor();
    int startY = (start.y / chunkSize).floor();
    int startZ = (start.z / chunkSize).floor();

    int endX = (end.x / chunkSize).floor();
    int endY = (end.y / chunkSize).floor();
    int endZ = (end.z / chunkSize).floor();

    for(int x = startX; x <= endX; x++){
      for(int y = startY; y <= endY; y++){
        for(int z = startZ; z <= endZ; z++){
          occupiedChunks.add(Vector3(x.toDouble(), y.toDouble(), z.toDouble()));
        }
      }
    }

    return occupiedChunks;
  }
}