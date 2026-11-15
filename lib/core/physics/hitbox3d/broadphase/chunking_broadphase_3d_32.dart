
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../hitbox3d_32.dart';
import '../misc/aabb_listener_32.dart';
import '../misc/prospect_pool.dart';
import 'broadphase_3d_32.dart';

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
  final _prospectPool = ProspectPool3D<T>();

  @override
  void add(T item) {
    _hitboxes[item.id] = item;

    final Set<Vector3> chunks = _getChunksOfHitbox(item);

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

    // Use the chunks the item was registered in, its current aabb may already
    // be different (e.g. it moved without notifying us).
    final registeredChunks = _lastKnownChunks.remove(item.id) ?? const {};
    for (final chunk in registeredChunks) {
      _chunks[chunk]?.remove(item.id);
      if (_chunks[chunk]?.isEmpty ?? false) {
        _chunks.remove(chunk);
      }
    }
    item.removeAabbListener(this);
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
    updateHitbox(hitbox); //todo this gets called every frame for animatedGameCharacters. fix.
  }

  @override
  Iterable<CollisionProspect<T>> query() {

    _potentials.clear();
    _prospectPool.reset();
    for (final item in _hitboxes.values) {
      // Only active hitboxes drive the search, passive ones are only found.
      if (item.collisionType != CollisionType.active) continue;

      // The chunks are kept up to date by updateHitbox, no need to recompute.
      final itemChunks = _lastKnownChunks[item.id] ?? const {};

      for (final chunk in itemChunks) {
        final hitboxIdsInChunk = _chunks[chunk];
        if (hitboxIdsInChunk == null) continue;

        for (final hitboxId in hitboxIdsInChunk) {
          final other = _hitboxes[hitboxId];
          if (other == null || identical(other, item)) continue;

          if (_shouldPair(item, other)) {
            _potentials.add(_prospectPool.acquire(item, other));
          }
        }
      }
    }
    return _potentials;
  }

  // Decides whether visiting [other] from [item] should produce a
  // [CollisionProspect].
  //
  // * [item] is always [CollisionType.active] (the outer loop of [query]
  //   skips everything else).
  // * [other] is any hitbox sharing a chunk with [item] (never [item] itself)
  //   and can be active, passive or inactive.
  // * Every unordered pair {item, other} must be produced by at least one
  //   visit, and should be produced by only one, since every acquire uses up
  //   a pool slot.
  bool _shouldPair(T item, T other) {

    if(item.collisionType == CollisionType.active){
      switch (other.collisionType) {
      case CollisionType.inactive: return false;
      case CollisionType.passive:  return true;
      case CollisionType.active:   return item.id < other.id;
      }
    } else {return false;}
  }


  Set<Vector3> _getChunksOfHitbox(Hitbox3D hitbox){
    final Set<Vector3> occupiedChunks = {};

    final Vector3 start = hitbox.aabb.min - Vector3.all(0.1);
    final Vector3 end = hitbox.aabb.max + Vector3.all(0.1);


    final int startX = (start.x / chunkSize).floor();
    final int startY = (start.y / chunkSize).floor();
    final int startZ = (start.z / chunkSize).floor();

    final int endX = (end.x / chunkSize).floor();
    final int endY = (end.y / chunkSize).floor();
    final int endZ = (end.z / chunkSize).floor();

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