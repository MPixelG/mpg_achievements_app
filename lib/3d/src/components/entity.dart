import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
abstract class Entity<TState> extends PositionComponent3d {
  late TState _state;
  TState get currentState => _state;
  String? modelPath;

  
  Entity({
      super.children,
      super.priority,
      super.key,
      super.position,
      required super.size,
      super.anchor,
      ThermionAsset? asset,
      this.modelPath,
    }){
    _state = initState();
  }
  
  int? get entityId => asset?.entity;
  
  @override
  void update(double dt) {
    tickClient(dt);
    
    final TState? nextState = tickServer(dt);
    if(nextState != null) _state = nextState;
    
    super.update(dt);
  }
  
  
  void tickClient(double dt) {
    if (entityId != null) {
      FilamentApp.instance?.setTransform(entityId!, transform.transformMatrix);
    }
  }

  ///
  /// tick method for the content that is managed server-side. You can only update the state server side, so this is the only way of changing values of your entity state
  /// returns the state of the next frame
  
  TState? tickServer(double dt) => null;
  
  TState initState();
}