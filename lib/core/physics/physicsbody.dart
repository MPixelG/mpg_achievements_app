import 'package:mpg_achievements_app/3d/src/components/position_component_3d.dart';
import 'package:vector_math/vector_math_64.dart';

mixin Physicsbody on PositionComponent3d {

  double mass = 1.0;
  final Vector3 acceleration = Vector3.zero();



void applyForces(Vector3 force){

  acceleration.add(force/mass);

}

void updatePhysics(double dt){

  velocity.add(acceleration*dt);

  acceleration.setZero();


}

}