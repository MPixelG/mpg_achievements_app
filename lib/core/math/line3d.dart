import 'dart:math';

import 'package:flame/components.dart';

/// An infinite line in the 3D Cartesian space lying on the z=0 plane, represented in the form
/// of ax + by = c.
///
/// If you just want to represent a part of a line, look into LineSegment.
class Line3D {
  final double a;
  final double b;
  final double c;

  const Line3D(this.a, this.b, this.c);

  Line3D.fromPoints(Vector3 p1, Vector3 p2)
      : this(
          p2.y - p1.y,
          p1.x - p2.x,
          p2.y * p1.x - p1.y * p2.x,
        );

  /// Returns an empty list if there is no intersection
  /// If the lines are concurrent it returns one point in the list.
  /// If they coincide it returns an empty list as well
  List<Vector3> intersections(Line3D otherLine) {
    const double eps = 1e-9;
    final determinant = a * otherLine.b - otherLine.a * b;
    if (determinant.abs() < eps) {
      final coincidentA = (a * otherLine.c - otherLine.a * c).abs() < eps;
      final coincidentB = (b * otherLine.c - otherLine.b * c).abs() < eps;
      if (coincidentA && coincidentB) {
        return [];
      }
      return [];
    }
    final x = (otherLine.b * c - b * otherLine.c) / determinant;
    final y = (a * otherLine.c - otherLine.a * c) / determinant;
    return [Vector3(x, y, 0.0)];
  }

  /// The angle of this line in relation to the x-axis
  double get angle => atan2(-a, b);

  @override
  String toString() {
    final ax = '${a}x';
    final by = b.isNegative ? '${b}y' : '+${b}y';
    return '$ax$by=$c';
  }
}