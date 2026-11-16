import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/3d/src/components/thermion_asset_container.dart';
import 'package:mpg_achievements_app/3d/src/renderable3d.dart';

import '../camera/camera.dart';
abstract class Entity<TState> extends PositionComponent3d with ThermionAssetContainer, CameraFollowable implements Renderable3d {
  late TState _state;
  TState get currentState => _state;
  @override
  String modelPath;
  String? name;
  
  Entity({
      super.children,
      super.priority,
      super.key,
      super.position,
      required super.size,
      super.anchor,
      required this.modelPath,
      this.name,
    }){
    _state = initState();
  }
  
  
  
  
  @override
  void update(double dt) {
    tickClient(dt);
    
    final TState? nextState = tickServer(dt);
    if(nextState != null) _state = nextState;
    
    super.update(dt);
  }
  
  
  // true while the last transform update is still queued on thermion's render thread
  bool _transformPending = false;

  void tickClient(double dt) {
    if (entityId == null || _transformPending) return;
    // applyTransform sets the transform on thermion's render thread (see
    // setTransformOnRenderThread); at most one call is in flight, so no
    // backlog builds up if thermion falls behind. The matrix is copied before
    // the call returns, so no clone is needed.
    _transformPending = true;
    applyTransform(transform.transformMatrix)
        .whenComplete(() => _transformPending = false);
  }

  /// tick method for the content that is managed server-side. You can only update the state server side, so this is the only way of changing values of your entity state
  /// returns the state of the next frame
  
  TState? tickServer(double dt) => null;
  
  TState initState();


  
}