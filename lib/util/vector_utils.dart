
import 'package:vector_math/vector_math.dart';

extension VectorComparing on Vector3 {
  int compareTo(Vector3 gridPos) {
    return (distanceTo(
      Vector3.zero(),
    ).compareTo(gridPos.distanceTo(Vector3.zero())));
  }
}