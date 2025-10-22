/* //deprecated
import 'package:flame/components.dart';
import 'package:mpg_achievements_app/core/physics/hitbox3d/hitbox3d.dart';
import 'package:mpg_achievements_app/mpg_pixel_adventure.dart';
import 'package:mpg_achievements_app/util/utils.dart';

class HitboxGrid extends Component {
  final Map<Vector3, List<Hitbox3D>> _chunks = {};
  static const double chunkSize = 4;

  void addHitbox(Hitbox3D hitbox){
    Set<Vector3> occupiedChunks = getChunksOfHitbox(hitbox);
    for(Vector3 chunkPos in occupiedChunks){
      if(!_chunks.containsKey(chunkPos)){
        _chunks[chunkPos] = [];
      }
      _chunks[chunkPos]!.add(hitbox);
    }
  }

  void removeHitbox(Hitbox3D hitbox){
    Set<Vector3> occupiedChunks = getChunksOfHitbox(hitbox);
    for(Vector3 chunkPos in occupiedChunks){
      _chunks[chunkPos]?.remove(hitbox);
      if(_chunks[chunkPos]?.isEmpty ?? false){
        _chunks.remove(chunkPos);
      }
    }
  }

  Set<Vector3> getChunksOfHitbox(Hitbox3D hitbox){
    Set<Vector3> occupiedChunks = {};
    Vector3 start = hitbox.position;
    Vector3 end = hitbox.secondPosition;


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
}*/ //deprecated
