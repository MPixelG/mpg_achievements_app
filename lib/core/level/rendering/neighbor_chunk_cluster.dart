
import 'package:mpg_achievements_app/core/level/isometric/isometric_renderable.dart';
import 'package:mpg_achievements_app/core/level/rendering/chunk.dart';

class NeighborChunkCluster {
  Chunk? top;
  Chunk? right;
  Chunk? left;
  Chunk? bottom;
  Chunk? topRight;
  Chunk? topLeft;
  Chunk? bottomRight;
  Chunk? bottomLeft;
  NeighborChunkCluster({
    this.top,
    this.right,
    this.left,
    this.bottom,
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  List<Chunk> getWhereContained(IsometricRenderable renderable) {
    final List<Chunk> out = [];

    if (top != null && top!.containsRenderable(renderable)) out.add(top!);
    if (right != null && right!.containsRenderable(renderable)) out.add(right!);
    if (left != null && left!.containsRenderable(renderable)) out.add(left!);
    if (bottom != null && bottom!.containsRenderable(renderable)) {
      out.add(bottom!);
    }
    if (topRight != null && topRight!.containsRenderable(renderable)) {
      out.add(topRight!);
    }
    if (topLeft != null && topLeft!.containsRenderable(renderable)) {
      out.add(topLeft!);
    }
    if (bottomRight != null && bottomRight!.containsRenderable(renderable)) {
      out.add(bottomRight!);
    }
    if (bottomLeft != null && bottomLeft!.containsRenderable(renderable)) {
      out.add(bottomLeft!);
    }

    return out;
  }
}