import 'package:thermion_dart/thermion_dart.dart' hide Vector3;
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';

//global switch for all debug frames

bool showDebugVisuals = true;

mixin ThermionDebugVisual on PositionComponent3d {
  ThermionAsset? _debugAsset;
  ThermionViewer? _viewer;
  // remembered so the frame can be recreated when debug visuals are toggled on
  bool _debugRequested = false;
  Vector4? _debugColor;
  // true while createGeometry is running, prevents creating two assets
  bool _debugCreating = false;
  double get modelScale => 0.01;

  // reused every frame to avoid allocations
  final Matrix4 _worldMatrix = Matrix4.identity();
  // last matrix sent to thermion, null forces the next update to send
  Matrix4? _lastSentMatrix;
  // true while a setTransform call is still being processed by thermion
  bool _transformPending = false;

  // activate debug visuals
  Future<void> enableDebugVisual(
    ThermionViewer viewer, {
    Vector4? color,
  }) async {
    _viewer = viewer;
    _debugRequested = true;
    _debugColor = color;
    if (!showDebugVisuals) return;
    if (_debugAsset != null || _debugCreating) return;

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
    //keepData/addToScene were removed from the API; data is stored on the GPU
    //and the asset is added to the scene by default
    _debugCreating = true;
    try {
      _debugAsset = await viewer.createGeometry(geometry);
    } finally {
      _debugCreating = false;
    }
    // debug visuals were switched off while the asset was being created
    if (!showDebugVisuals) disableDebugVisual();
  }

  // shows or hides this component's debug frame according to
  // [showDebugVisuals]; only components that requested a frame get one
  Future<void> applyDebugVisibility() async {
    if (!_debugRequested || _viewer == null) return;
    if (showDebugVisuals) {
      await enableDebugVisual(_viewer!, color: _debugColor);
    } else {
      disableDebugVisual();
    }
  }

  //called in update of component
  void updateDebugVisual(double dt) {
    if (_debugAsset == null || _viewer == null) return;
    // don't queue up calls while thermion is still busy with the last one
    if (_transformPending) return;

    final worldMatrix = _worldMatrix;

    if (parent is PositionComponent3d) {
      //get parent matrix
      worldMatrix.setFrom((parent as PositionComponent3d).transformMatrix);
      worldMatrix.multiply(transformMatrix);
    } else {
      worldMatrix.setFrom(transformMatrix);
      // Offset down by half the height to correct for bottomCenter anchor
      worldMatrix.translateByDouble(0.0, -size.y / 2, 0.0, 1.0);
    }

    // static objects (e.g. tiles) don't move, so only send changed transforms
    if (_lastSentMatrix == worldMatrix) return;
    (_lastSentMatrix ??= Matrix4.zero()).setFrom(worldMatrix);

    _transformPending = true;
    _debugAsset!
        .setTransform(worldMatrix.clone(), entity: _debugAsset!.entity)
        .whenComplete(() => _transformPending = false);
  }

  //refrsh after resize
  Future<void> refreshDebugVisual() async {
    if (_viewer == null) return;

    disableDebugVisual();

    await enableDebugVisual(_viewer!, color: _debugColor);
  }

  // remove
  void disableDebugVisual() {
    if (_debugAsset != null && _viewer != null) {
      FilamentApp.instance!.destroyAsset(_debugAsset!);
    }
    _debugAsset = null;
    // a new asset has to receive its transform again
    _lastSentMatrix = null;
  }
}
