import 'package:flame/geometry.dart' as geometry;
import 'package:flutter/cupertino.dart' hide Matrix4;
import 'package:vector_math/vector_math.dart';

import 'notifying_vector_3.dart';

/// This class describes a generic 2D transform, which is a combination of
/// translations, rotations, reflections and scaling. These transforms are
/// combined into a single matrix, that can be either applied to a canvas,
/// composed with another transform, or used directly to convert coordinates.
///
/// The transform can be visualized as 2 reference frames: a "global" and
/// a "local". At first, these two reference frames coincide. Then, the
/// following sequence of transforms is applied:
///   - translation to point [position];
///   - rotation by [angle] radians clockwise;
///   - scaling in X and Y directions by [scale] factors;
///   - final translation by [offset], in local coordinates.
///
/// The class is optimized for repeated use: the transform matrix is cached
/// and then recalculated only when the underlying properties change. Moreover,
/// recalculation of the transform is postponed until the matrix is actually
/// requested by the user. Thus, modifying multiple properties at once does
/// not incur the penalty of unnecessary recalculations.
///
/// This class implements the [ChangeNotifier] API, allowing you to subscribe
/// for notifications whenever the transform matrix changes. In addition, you
/// can subscribe to get notified when individual components of the transform
/// change: [position], [scale], and [offset] (but not [angle]).
class Transform3D extends ChangeNotifier {
  final Matrix4 _transformMatrix;
  bool _recalculate;
  double _angleRoll;
  double _anglePitch;
  double _angleYaw;
  final NotifyingVector3 _position;
  final NotifyingVector3 _scale;
  final NotifyingVector3 _offset;

  Transform3D()
      : _transformMatrix = Matrix4.identity(),
        _recalculate = true,
        _angleRoll = 0,
        _anglePitch = 0,
        _angleYaw = 0,
        _position = NotifyingVector3.zero(),
        _scale = NotifyingVector3.all(1),
        _offset = NotifyingVector3.zero() {
    _position.addListener(_markAsModified);
    _scale.addListener(_markAsModified);
    _offset.addListener(_markAsModified);
  }

  factory Transform3D.copy(Transform3D other) => Transform3D()
    ..angleRoll = other.angleRoll
    ..anglePitch = other.anglePitch
    ..angleYaw = other.angleYaw
    ..position = other.position
    ..scale = other.scale
    ..offset = other.offset;

  /// Clone of this.
  Transform3D clone() => Transform3D.copy(this);

  /// Set this to the values of the [other] [Transform3D].
  void setFrom(Transform3D other) {
    angleRoll = other.angleRoll;
    anglePitch = other.anglePitch;
    angleYaw = other.angleYaw;
    position = other.position;
    scale = other.scale;
    offset = other.offset;
  }

  /// Check whether this transform is equal to [other], up to the given
  /// [tolerance]. Setting tolerance to zero will check for exact equality.
  /// Transforms are considered equal if their rotation angles are the same
  /// or differ by a multiple of 2π, and if all other transform parameters:
  /// translation, scale, and offset are the same.
  ///
  /// The [tolerance] parameter is in absolute units, not relative.
  bool closeTo(Transform3D other, {double tolerance = 1e-10}) {
    final deltaAngle = (angleRoll - other.angleRoll) % geometry.tau;
    assert(deltaAngle >= 0);
    return (deltaAngle <= tolerance ||
        deltaAngle >= geometry.tau - tolerance) &&
        (position.x - other.position.x).abs() <= tolerance &&
        (position.y - other.position.y).abs() <= tolerance &&
        (scale.x - other.scale.x).abs() <= tolerance &&
        (scale.y - other.scale.y).abs() <= tolerance &&
        (offset.x - other.offset.x).abs() <= tolerance &&
        (offset.y - other.offset.y).abs() <= tolerance;
  }

  /// The translation part of the transform. This translation is applied
  /// relative to the global coordinate space.
  ///
  /// The returned vector can be modified by the user, and the changes
  /// will be propagated back to the transform matrix.
  NotifyingVector3 get position => _position;
  set position(Vector3 position) => _position.setFrom(position);

  /// X coordinate of the translation transform.
  double get x => _position.x;
  set x(double x) => _position.x = x;

  /// Y coordinate of the translation transform.
  double get y => _position.y;
  set y(double y) => _position.y = y;

  /// The rotation part of the transform. This represents rotation around
  /// the [position] point in clockwise direction by [angle] radians. If
  /// the angle is negative then the rotation is counterclockwise.
  double get angleRoll => _angleRoll;
  set angleRoll(double a) {
    _angleRoll = a;
    _markAsModified();
  }

  /// Similar to [angle], but uses degrees instead of radians.
  double get angleRollDegrees => angleRoll * (360 / geometry.tau);
  set angleRollDegrees(double a) {
    angleRoll = a * (geometry.tau / 360);
    _markAsModified();
  }

  /// The rotation part of the transform. This represents rotation around
  /// the [position] point in clockwise direction by [angle] radians. If
  /// the angle is negative then the rotation is counterclockwise.
  double get anglePitch => _anglePitch;
  set anglePitch(double a) {
    _anglePitch = a;
    _markAsModified();
  }

  /// Similar to [angle], but uses degrees instead of radians.
  double get anglePitchDegrees => anglePitch * (360 / geometry.tau);
  set anglePitchDegrees(double a) {
    anglePitch = a * (geometry.tau / 360);
    _markAsModified();
  }

  /// The rotation part of the transform. This represents rotation around
  /// the [position] point in clockwise direction by [angle] radians. If
  /// the angle is negative then the rotation is counterclockwise.
  double get angleYaw => _angleYaw;
  set angleYaw(double a) {
    _angleYaw = a;
    _markAsModified();
  }

  /// Similar to [angle], but uses degrees instead of radians.
  double get angleYawDegrees => angleYaw * (360 / geometry.tau);
  set angleYawDegrees(double a) {
    angleYaw = a * (geometry.tau / 360);
    _markAsModified();
  }

  /// The scale part of the transform. The default scale factor is (1, 1),
  /// a scale greater than 1 corresponds to expansion, and less than 1 is
  /// contraction. A negative scale is also allowed, and it corresponds
  /// to a mirror reflection around the corresponding axis.
  /// Scale factors can be different for X and Y directions.
  ///
  /// The returned vector can be modified by the user, and the changes
  /// will be propagated back to the transform matrix.
  NotifyingVector3 get scale => _scale;
  set scale(Vector3 scale) => _scale.setFrom(scale);

  /// Additional offset applied after all other transforms. Unlike other
  /// transforms, this offset is applied in the local coordinate system.
  /// For example, an [offset] of (1, 0) describes a shift by 1 unit along
  /// the X axis, however, this shift is applied after that axis was
  /// repositioned, rotated and scaled.
  ///
  /// The returned vector can be modified by the user, and the changes
  /// will be properly applied to the transform matrix.
  NotifyingVector3 get offset => _offset;
  set offset(Vector3 offset) => _offset.setFrom(offset);

  /// Flip the coordinate system horizontally.
  void flipHorizontally() {
    _scale.x = -_scale.x;
  }

  /// Flip the coordinate system vertically.
  void flipVertically() {
    _scale.y = -_scale.y;
  }

  /// The total transformation matrix for the component. This matrix combines
  /// translation, rotation, reflection and scale transforms into a single
  /// entity. The matrix is cached and gets recalculated only as necessary.
  ///
  /// The returned matrix must not be modified by the user.
  Matrix4 get transformMatrix {
    if (_recalculate) {
      _transformMatrix.setIdentity();
      _transformMatrix.translate(_position.x, _position.y, _position.z);
      _transformMatrix.rotateZ(_angleRoll);
      _transformMatrix.rotateY(_angleYaw);
      _transformMatrix.rotateX(_anglePitch);
      _transformMatrix.scale(_scale.x, _scale.y, _scale.z);
      _transformMatrix.translate(_offset.x, _offset.y, _offset.z);
      _recalculate = false;
    }
    return _transformMatrix;
  }

  /// Transform [point] from local coordinates into the parent coordinate space.
  /// Effectively, this function applies the current transform to [point].
  ///
  /// Use [output] to send in a Vector3 object that will be used to avoid
  /// creating a new Vector3 object in this method.
  Vector3 localToGlobal(Vector3 point, {Vector3? output}) {
    final m = transformMatrix.storage;
    final x = m[0] * point.x + m[4] * point.y + m[12];
    final y = m[1] * point.x + m[5] * point.y + m[13];
    final z = m[2] * point.x + m[6] * point.y + m[14];
    return (output?..setValues(x, y, z)) ?? Vector3(x, y, z);
  }

  /// Transform [point] from the global coordinate space into the local
  /// coordinates. Thus, this method performs the inverse of the current
  /// transform.
  ///
  /// If the current transform is degenerate due to one of the scale
  /// factors being 0, then this method will return a zero vector.
  ///
  /// Use [output] to send in a Vector3 object that will be used to avoid
  /// creating a new Vector3 object in this method.
  Vector3 globalToLocal(Vector3 point, {Vector3? output}) {
    // Here we rely on the fact that in the transform matrix only elements
    // `m[0]`, `m[1]`, `m[4]`, `m[5]`, `m[12]`, and `m[13]` are modified.
    // This greatly simplifies computation of the inverse matrix.
    final m = transformMatrix.storage;
    var det = m[0] * m[5] - m[1] * m[4];
    if (det != 0) {
      det = 1 / det;
    }
    final x = ((point.x - m[12]) * m[5] - (point.y - m[13]) * m[4]) * det;
    final y = ((point.y - m[13]) * m[0] - (point.x - m[12]) * m[1]) * det;
    final z = ((point.y - m[14]) * m[0] - (point.x - m[11]) * m[1]) * det;
    return (output?..setValues(x, y, z)) ?? Vector3(x, y, z);
  }

  /// Whether the transform represents a pure translation, i.e. a transform of
  /// the form `(x, y) -> (x + Δx, y + Δy)`.
  bool get isTranslation {
    return _angleRoll == 0 && _scale.x == 1 && _scale.y == 1;
  }

  /// Whether the transform keeps horizontal (vertical) lines as horizontal
  /// (vertical).
  bool get isAxisAligned => _angleRoll == 0;

  /// Whether the transform preserves angles. A conformal transformation may
  /// consist of a translation, rotation, and uniform scaling. A reflection is
  /// not considered conformal.
  bool get isConformal => _scale.x == _scale.y;

  /// Whether the transform includes a reflection, i.e. it flips the orientation
  /// of the coordinate system.
  bool get hasReflection => _scale.x.sign * _scale.y.sign == -1;

  void _markAsModified() {
    _recalculate = true;
    notifyListeners();
  }
}