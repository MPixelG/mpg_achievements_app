import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/utils.dart';

class HitboxGrid extends Component {
  final Map<Vector3, List<Hitbox3D>> _chunks = {};
  final List<Hitbox3D> bigHitboxes = [];
  static final Vector3 chunkSize = tilesize * 16;

  void addHitbox(Hitbox3D hitbox){
    if(_isBigHitbox(hitbox)){
     bigHitboxes.add(hitbox);
      return;
    }
    final chunk = getChunkOfHitbox(hitbox);
    _chunks.putIfAbsent(chunk, () => []).add(hitbox);
  }

  bool _isBigHitbox(Hitbox3D hitbox) => max(((hitbox.position - hitbox.secondPosition).clone()..absolute()).storage) > chunkSize.x;

  void removeHitbox(Hitbox3D hitbox){
    if(_isBigHitbox(hitbox)) {
      bigHitboxes.remove(hitbox);
      return;
    }

    final chunk = getChunkOfHitbox(hitbox);
    final list = _chunks[chunk];
    list?.remove(hitbox);
    if (list != null && list.isEmpty) {
      _chunks.remove(chunk);
    }
  }

  Vector3 getChunkOfHitbox(Hitbox3D hitbox){
    final pos = hitbox.position;
    return Vector3((pos.x / chunkSize.x).floorToDouble(), (pos.y / chunkSize.y).floorToDouble(), (pos.z / chunkSize.z).floorToDouble());
  }
}