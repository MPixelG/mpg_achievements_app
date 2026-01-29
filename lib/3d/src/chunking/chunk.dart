import 'package:mpg_achievements_app/3d/src/chunking/tiles/tile.dart';
import 'package:mpg_achievements_app/3d/src/game.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

class Chunk {
  List<Tile> tiles = [];
  
  int lod;
  Vector2 position;
  
  Chunk(this.lod, this.position);
  
  static Future<void> onLoad() async {
    
    //placeholder plane with no material
    final List<double> vertices = [
      -0.5,  0.5, -0.5,
      -0.5, -0.5, -0.5,
      0.5, -0.5, -0.5,
      0.5,  0.5, -0.5
    ].map<double>((e) => e+2).toList();
    

    final List<int> indices = [
      0, 1, 2,
      2, 3, 0
    ];

    final List<double> normals = [
      0, 0, 1,
      1, 0, 0,
      0, 0, -1,
      -1, 0, 0,
      0, 1, 0,
      0, -1, 0,
    ];

    final List<double> texCoords = [
      0,1,
      0,0,
      1,0,
      1,1
    ];
    
    await thermion!.createGeometry(Geometry(Float32List.fromList(vertices), indices), materialInstances: [
      (await FilamentApp.instance!.createUbershaderMaterialInstance(doubleSided: true))
    ]);
  }
  
  
}