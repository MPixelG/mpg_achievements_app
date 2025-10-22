import 'package:flame/extensions.dart';
import 'package:mpg_achievements_app/core/math/line3d.dart';

/// A [LineSegment] represent a segment of an infinitely long line, it is the
/// segment between the [from] and [to] vectors (inclusive).
class LineSegment3D {
  final Vector3 from;
  final Vector3 to;

  /// Creates a [LineSegment] given a start ([from]) point and an end ([to])
  /// point.
  LineSegment3D(this.from, this.to);

  /// Creates a [LineSegment] starting at a given a [start] point and following
  /// a certain [direction] for a given [length].
  LineSegment3D.withLength({
    required Vector3 start,
    required Vector3 direction,
    required double length,
  }) : this(start, start + direction.normalized() * length);

  factory LineSegment3D.zero() => LineSegment3D(Vector3.zero(), Vector3.zero());

  /// A unit vector representing the direction of the line segment.
  Vector3 get direction {
    final v = to - from;
    v.normalize();
    return v;
  }

  /// The length of the line segment.
  double get length => (to - from).length;

  /// The point in the center of this line segment.
  Vector3 get midpoint {
    final m = from + to;
    m.scale(0.5);
    return m;
  }

  /// Spreads points evenly along the line segment.
  /// A number of points [amount] are returned; the edges are not included.
  List<Vector3> spread(int amount) {
    if (amount < 0) {
      throw ArgumentError('Amount must be non-negative');
    }
    if (amount == 0) {
      return [];
    }

    final step = length / (amount + 1);
    return [
      for (var i = 1; i <= amount; i++) from + direction * (i * step),
    ];
  }

  /// Returns a new [LineSegment] translated by a given displacement [offset].
  LineSegment3D translate(Vector3 offset) {
    return LineSegment3D(from + offset, to + offset);
  }

  /// Returns a new [LineSegment] with same direction but extended by [amount]
  /// on both sides.
  LineSegment3D inflate(double amount) {
    final direction = this.direction;
    return LineSegment3D(from - direction * amount, to + direction * amount);
  }

  /// Returns a new [LineSegment] with same direction but reduced by [amount]
  /// on both sides.
  LineSegment3D deflate(double amount) {
    return inflate(-amount);
  }

  /// Returns an empty list if there are no intersections between the segments
  /// If the segments are concurrent, the intersecting point is returned as a
  /// list with a single point
  List<Vector3> intersections(LineSegment3D otherSegment) {
    final result = toLine().intersections(otherSegment.toLine());
    if (result.isNotEmpty) {
      // The lines are not parallel
      final intersection = result.first;
      if (containsPoint(intersection) &&
          otherSegment.containsPoint(intersection)) {
        // The intersection point is on both line segments
        return result;
      }
    } else {
      // In here we know that the lines are parallel
      final overlaps = {
        if (otherSegment.containsPoint(from)) from,
        if (otherSegment.containsPoint(to)) to,
        if (containsPoint(otherSegment.from)) otherSegment.from,
        if (containsPoint(otherSegment.to)) otherSegment.to,
      };
      if (overlaps.isNotEmpty) {
        final sum = Vector3.zero();
        for (final overlap in overlaps) {
          sum.add(overlap);
        }
        return [sum..scale(1 / overlaps.length)];
      }
    }
    return [];
  }

  /// Whether the given [point] lies in this line segment.
  /// This performs a 3D collinearity check (cross product) and then verifies
  /// the projection falls within the segment extents.
  bool containsPoint(Vector3 point, {double epsilon = 1e-6}) {
    final delta = to - from;
    final toPoint = point - from;

    // 3D cross product: if non-zero the point is not collinear.
    final cross = delta.cross(toPoint);
    if (cross.length > epsilon) {
      return false;
    }

    // Check projection along the segment direction.
    final dotProduct = toPoint.dot(delta);
    if (dotProduct < -epsilon) {
      return false;
    }

    final squaredLength = from.distanceToSquared(to);
    if (dotProduct > squaredLength + epsilon) {
      return false;
    }

    return true;
  }

  bool pointsAt(Line3D line) {
    final result = toLine().intersections(line);
    if (result.isNotEmpty) {
      final delta = to - from;
      final intersection = result.first;
      final dirToIntersection = intersection - from;
      // If the intersection lies in front of `from` along the segment direction.
      if (delta.dot(dirToIntersection) >= -1e-6) {
        return true;
      }
    }
    return false;
  }

  Line3D toLine() => Line3D.fromPoints(from, to);

  @override
  String toString() {
    return '[$from, $to]';
  }
}