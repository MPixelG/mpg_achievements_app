import 'package:thermion_dart/thermion_dart.dart' hide Vector3;
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:vector_math/vector_math_64.dart'; // Pfad anpassen

mixin ThermionDebugVisual on PositionComponent3d {
  ThermionAsset? _debugAsset;
  ThermionViewer? _viewer;
  double get modelScale => 0.01;

  // activate debug visuals
  Future<void> enableDebugVisual(
    ThermionViewer viewer, {
    Vector4? color,
  }) async {
    if (_debugAsset != null) return;
    _viewer = viewer;

    final activeColor = color ?? Vector4(1.0, 0.0, 0.0, 1.0);

    //(Wireframe Box)
    // Box relative to Anchor (0,0,0) of component,
    final w = size.x;
    final h = size.y;
    final d = size.z;

    print("debug:");
    print(size);

    // 8 edges of box with Anchor-Offset
    final vertices = Float32List.fromList([
      0, 0, 0, w, 0, 0, w, 0, d, 0, 0, d, // Boden
      0, h, 0, w, h, 0, w, h, d, 0, h, d, // Decke
    ]);

    // Line-Indices
    final indices = Uint16List.fromList([
      0, 1, 1, 2, 2, 3, 3, 0, // bottom
      4, 5, 5, 6, 6, 7, 7, 4, // top
      0, 4, 1, 5, 2, 6, 3, 7, // vertical
    ]);

    //color needs to be handed over in Float32List
    const numVertices = 8;
    final colors = Float32List(numVertices * 4);

    for (int i = 0; i < numVertices; i++) {
      colors[i * 4 + 0] = activeColor.r; // R
      colors[i * 4 + 1] = activeColor.g; // G
      colors[i * 4 + 2] = activeColor.b; // B
      colors[i * 4 + 3] = activeColor.a; // A
    }

    //color does not work
    final geometry = Geometry(
      vertices,
      indices,
      primitiveType: PrimitiveType.LINES,
      attribute0: colors,
      createDummyColors: false,
    );

    // create asset
    _debugAsset = await viewer.createGeometry(
      geometry,
      keepData: false, //data is stored on the GPU
      addToScene: true, //add to scene
    );
  }

  //called in update of component
  void updateDebugVisual(double dt) {
    if (_debugAsset == null || _viewer == null) return;

    final Matrix4 worldMatrix;

    if (parent is PositionComponent3d) {
      //get parent matrix
      worldMatrix = (parent as PositionComponent3d).transformMatrix.clone();
      worldMatrix.multiply(transformMatrix);
    } else {
      worldMatrix = transformMatrix.clone();
      // Offset down by half the height to correct for bottomCenter anchor
      worldMatrix.translateByVector3(Vector3(0.0,-size.y/2,0.0));

    }

    _debugAsset!.setTransform(worldMatrix, entity: _debugAsset!.entity);
  }

  //refrsh after resize
  Future<void> refreshDebugVisual() async {
    if (_viewer == null) return;

    disableDebugVisual();

    await enableDebugVisual(_viewer!);
  }

  // remove
  void disableDebugVisual() {
    if (_debugAsset != null && _viewer != null) {
      FilamentApp.instance!.destroyAsset(_debugAsset!);
    }
    _debugAsset = null;
  }
}
