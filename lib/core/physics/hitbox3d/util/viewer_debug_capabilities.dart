import 'dart:typed_data';
import 'package:thermion_dart/thermion_dart.dart' hide Vector3;
import 'package:vector_math/vector_math_64.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart'; // Pfad anpassen

mixin ThermionDebugVisual on PositionComponent3d {
  ThermionAsset? _debugAsset;
  ThermionViewer? _viewer;


  // activate debug visuals
  Future<void> enableDebugVisual(ThermionViewer viewer) async {
    if (_debugAsset != null) return;
    _viewer = viewer;

    //(Wireframe Box)
    // Box relative to Anchor (0,0,0) of component,
    final w = width;
    final h = height;
    final d = depth;

    // 8 edges of box with Anchor-Offset
    final vertices = Float32List.fromList([
      0, 0, 0,  w, 0, 0,  w, 0, d,  0, 0, d, // Boden
      0, h, 0,  w, h, 0,  w, h, d,  0, h, d, // Decke
    ]);

    // Line-Indices
    final indices = Uint16List.fromList([
      0, 1, 1, 2, 2, 3, 3, 0, // bottom
      4, 5, 5, 6, 6, 7, 7, 4, // top
      0, 4, 1, 5, 2, 6, 3, 7 // vertical
    ]);

    final geometry = Geometry(
      vertices,
      indices,
      primitiveType: PrimitiveType.LINES,
          );

    // create asset

    _debugAsset = await viewer.createGeometry(
        geometry,
        keepData: false, //data is stored on the GPU
        addToScene: true //add to scene
    );
  }


  //called in update of component
  void updateDebugVisual(double dt) {
    if (_debugAsset == null || _viewer == null) return;

    final Matrix4 worldMatrix;

    if(parent is PositionComponent3d) {
     //get parent matrix
      worldMatrix = (parent as PositionComponent3d).transformMatrix.clone();
      worldMatrix.multiply(transformMatrix);
      FilamentApp.instance!.setTransform(_debugAsset!.entity, worldMatrix);
    } else {return;}


  }

  // remove
  void disableDebugVisual() {
    if (_debugAsset != null && _viewer != null) {

      FilamentApp.instance!.destroyAsset(_debugAsset!);
    }
    _debugAsset = null;
  }
}