import 'dart:ui';

import 'package:flame/components.dart';
import 'package:mpg_achievements_app/isometric/src/core/iso_component.dart';

abstract class ShapeComponent3D extends IsoPositionComponent with HasPaint {
  ShapeComponent3D({
    super.position,
    required super.size,
    super.scale,
    super.anchor,
    super.children,
    super.priority,
    super.key,
    Paint? paint,
    List<Paint>? paintLayers,
  }) {
    this.paint = paint ?? this.paint;
    // Only read from this.paintLayers if paintLayers not null to prevent
    // unnecessary creation of the paintLayers list.
    if (paintLayers != null) {
      this.paintLayers = paintLayers;
    }
  }

  bool renderShape = true;

  /// Whether the shape is solid or hollow.
  ///
  /// If it is solid, intersections will occur even if the other component is
  /// fully enclosed by the other hitbox. The intersection point in such cases
  /// will be the center of the enclosed [ShapeComponent3D].
  /// A hollow shape that is fully enclosed by a solid hitbox will cause an
  /// intersection result, but not the other way around.
  ///
  /// This field is not related to how the shape should be rendered, see
  /// [Paint.style] for that.
  bool isSolid = false;
}
