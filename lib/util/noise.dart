import 'dart:math' as math;

class PerlinNoise1D {
  static const int _tableSize = 256;
  late List<int> _permutation;
  late List<double> _gradient;

  PerlinNoise1D({int? seed}) {
    _initializePermutation(seed);
    _initializeGradient(seed);
  }

  void _initializePermutation(int? seed) {
    final random = math.Random(seed);
    _permutation = List.generate(_tableSize, (i) => i);

    for (int i = _tableSize - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final int temp = _permutation[i];
      _permutation[i] = _permutation[j];
      _permutation[j] = temp;
    }

    _permutation = [..._permutation, ..._permutation];
  }

  void _initializeGradient(int? seed) {
    final random = math.Random(seed);
    _gradient = List.generate(
      _tableSize,
      (i) => random.nextDouble() * 2.0 - 1.0,
    );

    _gradient = [..._gradient, ..._gradient];
  }

  double _fade(double t) => t * t * t * (t * (t * 6.0 - 15.0) + 10.0);

  double _lerp(double t, double a, double b) => a + t * (b - a);

  double noise(double x) {
    final int xi = x.floor() & 255;
    final double xf = x - x.floor();

    final double gradLeft = _gradient[_permutation[xi]];
    final double gradRight = _gradient[_permutation[xi + 1]];

    final double dotLeft = gradLeft * xf;
    final double dotRight = gradRight * (xf - 1.0);

    final double u = _fade(xf);
    return _lerp(u, dotLeft, dotRight);
  }

  double octaveNoise(double x, int octaves, double persistence) {
    double value = 0.0;
    double amplitude = 1.0;
    double frequency = 1.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      value += noise(x * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2.0;
    }

    return value / maxValue;
  }

  double turbulence(double x, int octaves, double persistence) {
    double value = 0.0;
    double amplitude = 1.0;
    double frequency = 1.0;
    double maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
      value += noise(x * frequency).abs() * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= 2.0;
    }

    return value / maxValue;
  }

  double normalizedNoise(double x, double min, double max) {
    final double n = noise(x);
    return min + (n + 1.0) * 0.5 * (max - min);
  }
}
