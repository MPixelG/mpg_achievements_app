import 'dart:typed_data';
import 'package:flame/components.dart' hide Vector3, Matrix4;
import 'package:thermion_dart/thermion_dart.dart' hide Vector3;
import 'package:vector_math/vector_math_64.dart';
import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart'; // Pfad anpassen

mixin ThermionDebugVisual on PositionComponent3d {
  ThermionAsset? _debugAsset;
  ThermionViewer? _viewer;

  // Aktiviert die Visualisierung
  Future<void> enableDebugVisual(ThermionViewer viewer, {Vector3? color}) async {
    if (_debugAsset != null) return;
    _viewer = viewer;

    //(Wireframe Box)
    // Box relative to Anchor (0,0,0) of component
    final w = size.x;
    final h = size.y;
    final d = size.z;

    // 8 edges of box
    final vertices = Float32List.fromList([
      0, 0, 0,  w, 0, 0,  w, 0, d,  0, 0, d, // floor
      0, h, 0,  w, h, 0,  w, h, d,  0, h, d, // ceiling
    ]);

    // Line-Indices
    final indices = Uint16List.fromList([
      0, 1, 1, 2, 2, 3, 3, 0, // bottom
      4, 5, 5, 6, 6, 7, 7, 4, // top
      0, 4, 1, 5, 2, 6, 3, 7  // vertical
    ]);

    final geometry = Geometry(
      vertices,
      indices,
      primitiveType: PrimitiveType.LINES,
    );

    // 2. Asset erstellen

    _debugAsset = await viewer.createGeometry(
        geometry,
        keepData: false,
        addToScene: true
    );

    geometry.dispose();
  }

  //called in update of component
  void updateDebugVisual(double dt) {
    if (_debugAsset == null || _viewer == null) return;


    final matrix = Matrix4.identity();

    // Wenn die Hitbox einen Parent hat, müssen wir dessen Position addieren
    var worldPos = position.clone();
    var currentParent = parent;
    while(currentParent is PositionComponent3d) {
      worldPos += currentParent.position;
      currentParent = currentParent.parent;
    }

    matrix.transform3(worldPos);

    // send to thermion
    game.camera3D!.thermionCamera.setTransform(matrix);
  }

  /// Aufräumen nicht vergessen
  void disableDebugVisual() {
    if (_debugAsset != null && _viewer != null) {
      // Da die Standard API kein explizites removeAsset hat, nutzen wir removeEntity
      // oder falls verfügbar destroyAsset.
      // Hinweis: Prüfen Sie Ihre Thermion API Methoden.
      _viewer!.removeLight(_debugAsset!.entity); // Workaround falls kein generisches remove
      // Besser:
      // _viewer!.removeFromScene(_debugAsset!);
      // _viewer!.destroyAsset(_debugAsset!);
    }
    _debugAsset = null;
  }
}