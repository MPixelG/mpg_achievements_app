import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:mpg_achievements_app/3d/src/components/thermion_asset_container.dart';
import 'package:mpg_achievements_app/3d/src/renderable3d.dart';
import 'package:thermion_flutter/thermion_flutter.dart';
abstract class Entity<TState> extends PositionComponent3d with ThermionAssetContainer implements Renderable3d {
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
  
  
  void tickClient(double dt) {
    if (entityId != null) {
      FilamentApp.instance?.setTransform(entityId!, transform.transformMatrix);
    }
  }

  /// tick method for the content that is managed server-side. You can only update the state server side, so this is the only way of changing values of your entity state
  /// returns the state of the next frame
  
  TState? tickServer(double dt) => null;
  
  TState initState();




  
}