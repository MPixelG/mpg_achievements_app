import 'package:flame/components.dart';
import 'package:mpg_achievements_app/components/util/noise.dart';

enum CameraEffect {
  shake
}
Vector2 shake({double strength = 5, double persistance = 1}) {
  double time1 = DateTime.now().millisecondsSinceEpoch.toDouble();
  double time2 = time1 + 100; // Offset to ensure different values

  PerlinNoise1D noise = PerlinNoise1D();

  double val1 = noise.octaveNoise(time1 / 10000+persistance, 3, 5);
  double val2 = noise.octaveNoise(time2 / 10000*persistance, 3, 5);

  // Normalize and scale
  return Vector2(
      (val1) * strength * 10,
      (val2) * strength * 10
  );
}