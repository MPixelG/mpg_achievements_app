import 'package:flame/components.dart';
import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile.dart';

class TileGrid {
  List<List<List<Tile?>>>? _tileGridData;
  final int size;
  
  TileGrid([this.size = 16]);
  
  void setTileAt(Vector3 pos, Tile tile){
    final int x = pos.x.toInt();
    final int y = pos.y.toInt();
    final int z = pos.z.toInt();
    if(x > size-1 || y > size-1 || z > size-1) return;
    setSafe<List<List<Tile?>>>(_tileGridData, x, [], []);
    setSafe<List<Tile?>>(_tileGridData![x], y, [], []);
    setSafe<Tile?>(_tileGridData![x][y], z, tile, null);
  }
  
  Tile? getTileAt(Vector3 pos){
    final int x = pos.x.toInt();
    final int y = pos.y.toInt();
    final int z = pos.z.toInt();
    
    if(x > size-1 || y > size-1 || z > size-1) return null;
    
    if(_tileGridData == null ||
      _tileGridData!.length < x ||
      _tileGridData![x].length < y ||
      _tileGridData![x][y].length < z
    ) {
      return null;
    } else {
      return _tileGridData![x][y][z];
    }
  }
  
  void setSafe<T>(List<T>? list, int index, T value, T filler){
    list ??= List.filled(index, filler, growable: true);
    if(index > list.length){
      final int fillAmount = index - (list.length-1);
      list.fillRange(fillAmount, index, filler);
    }
    list[index] = value;
  }
}