
import 'package:flutter/cupertino.dart';
import 'package:vector_math/vector_math.dart';

/// Represents a relative position inside some 2D object with a rectangular
/// size or bounding box.
///
/// Think of it as the place where you "grab" or "hold" the object.
/// In Components, the Anchor3D is where the component position is measured from.
/// For example, if a component position is (100, 100) the Anchor3D reflects what
/// exact point of the component that is positioned at (100, 100), as a relative
/// fraction of the size of the object.
///
/// The "default" Anchor3D in most cases is topLeft.
///
/// The Anchor3D is represented by a fraction of the size (in each axis),
/// where 0 in x-axis means left, 0 in y-axis means top, 1 in x-axis means right
/// and 1 in y-axis means bottom.
@immutable
class Anchor3D {
  static const Anchor3D topLeftLeft = Anchor3D(0.0, 1.0, 0.0);
  static const Anchor3D topLeftCenter = Anchor3D(0.0, 1.0, 0.5);
  static const Anchor3D topLeftRight = Anchor3D(0.0, 1.0, 1.0);
  static const Anchor3D topCenterLeft = Anchor3D(0.5, 1.0, 0.0);
  static const Anchor3D topCenterCenter = Anchor3D(0.5, 1.0, 0.5);
  static const Anchor3D topCenterRight = Anchor3D(0.5, 1.0, 1.0);
  static const Anchor3D topRightLeft = Anchor3D(1.0, 1.0, 0.0);
  static const Anchor3D topRightCenter = Anchor3D(1.0, 1.0, 0.5);
  static const Anchor3D topRightRight = Anchor3D(1.0, 1.0, 1.0);
  static const Anchor3D centerLeftLeft = Anchor3D(0.0, 0.5, 0.0);
  static const Anchor3D centerLeftCenter = Anchor3D(0.0, 0.5, 0.5);
  static const Anchor3D centerLeftRight = Anchor3D(0.0, 0.5, 1.0);
  static const Anchor3D center = Anchor3D(0.5, 0.5, 0.5);
  static const Anchor3D centerRightLeft = Anchor3D(1.0, 0.5, 0.0);
  static const Anchor3D centerRightRight = Anchor3D(1.0, 0.5, 1.0);
  static const Anchor3D centerRightCenter = Anchor3D(1.0, 0.5, 0.5);
  static const Anchor3D bottomLeftLeft = Anchor3D(0.0, 0.0, 0.0);
  static const Anchor3D bottomLeftRight = Anchor3D(0.0, 0.0, 1.0);
  static const Anchor3D bottomLeftCenter = Anchor3D(0.0, 0.0, 0.5);
  static const Anchor3D bottomCenterLeft = Anchor3D(0.5, 0.0, 0.0);
  static const Anchor3D bottomCenterRight = Anchor3D(0.5, 0.0, 1.0);
  static const Anchor3D bottomCenterCenter = Anchor3D(0.5, 0.0, 0.5);
  static const Anchor3D bottomRightLeft = Anchor3D(1.0, 0.0, 0.0);
  static const Anchor3D bottomRightRight = Anchor3D(1.0, 0.0, 1.0);
  static const Anchor3D bottomRightCenter = Anchor3D(1.0, 0.0, 0.5);

  /// The relative x position with respect to the object's width;
  /// 0 means totally to the left (beginning) and 1 means totally to the
  /// right (end).
  final double x;

  /// The relative y position with respect to the object's height;
  /// 0 means totally to the front (beginning) and 1 means totally to the
  /// back (end).
  final double y;

  /// The relative z position with respect to the object's depth;
  /// 0 means totally to the top (beginning) and 1 means totally to the
  /// bottom (end).
  final double z;

  /// Returns [x] and [y] as a Vector2. Note that this is still a relative
  /// fractional representation.
  Vector3 toVector3() => Vector3(x, y, z);

  const Anchor3D(this.x, this.y, this.z);

  /// Take your position [position] that is on this Anchor3D and give back what
  /// that position it would be on in Anchor3D [otherAnchor3D] with a size of
  /// [size].
  Vector2 toOtherAnchor3DPosition(
      Vector2 position,
      Anchor3D otherAnchor3D,
      Vector2 size, {
        Vector2? out,
      }) {
    if (this == otherAnchor3D) {
      return position;
    } else {
      return (out ?? Vector2.zero())
        ..setValues(otherAnchor3D.x - x, otherAnchor3D.y - y)
        ..multiply(size)
        ..add(position);
    }
  }

  /// Returns a string representation of this Anchor3D.
  ///
  /// This should only be used for serialization purposes.
  String get name {
    return _valueNames[this] ?? 'Anchor3D($x, $y)';
  }

  /// Returns a string representation of this Anchor3D.
  ///
  /// This is the same as `name` and should be used only for debugging or
  /// serialization.
  @override
  String toString() => name;

  static final Map<Anchor3D, String> _valueNames = {
    topLeftLeft :"topLeftLeft",
    topLeftCenter :"topLeftCenter",
    topLeftRight :"topLeftRight",
    topCenterLeft :"topCenterLeft",
    topCenterCenter :"topCenterCenter",
    topCenterRight :"topCenterRight",
    topRightLeft :"topRightLeft",
    topRightCenter :"topRightCenter",
    topRightRight :"topRightRight",
    centerLeftLeft :"centerLeftLeft",
    centerLeftCenter :"centerLeftCenter",
    centerLeftRight :"centerLeftRight",
    center :"center",
    centerRightLeft :"centerRightLeft",
    centerRightRight :"centerRightRight",
    centerRightCenter :"centerRightCenter",
    bottomLeftLeft :"bottomLeftLeft",
    bottomLeftRight :"bottomLeftRight",
    bottomLeftCenter :"bottomLeftCenter",
    bottomCenterLeft :"bottomCenterLeft",
    bottomCenterRight :"bottomCenterRight",
    bottomCenterCenter :"bottomCenterCenter",
    bottomRightLeft :"bottomRightLeft",
    bottomRightRight :"bottomRightRight",
  };

  /// List of all predefined Anchor3D values.
  static final List<Anchor3D> values = _valueNames.keys.toList();

  /// This should only be used for de-serialization purposes.
  ///
  /// If you need to convert Anchor3Ds to serializable data (like JSON),
  /// use the `toString()` and `valueOf` methods.
  factory Anchor3D.valueOf(String name) {
    if (_valueNames.containsValue(name)) {
      return _valueNames.entries.singleWhere((e) => e.value == name).key;
    } else {
      final regexp = RegExp(r'^\Anchor3D\(([^,]+), ([^\)]+)\)');
      final matches = regexp.firstMatch(name)?.groups([1, 2]);
      assert(
      matches != null && matches.length == 2,
      'Bad Anchor3D format: $name',
      );
      return Anchor3D(double.parse(matches![0]!), double.parse(matches[1]!), double.parse(matches[2]!));
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Anchor3D && x == other.x && y == other.y;
  }

  Vector3 operator *(Vector3 other) {
    return Vector3(x * other.x, y * other.y, z * other.z);
  }

  @override
  int get hashCode => x.hashCode * 31 + y.hashCode;
}