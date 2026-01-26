import 'package:vector_math/vector_math_64.dart';

Vector3 lerp(Vector3 a, Vector3 b, double t) => a * (1-t) + b*t;