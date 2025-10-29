import 'dart:math' as math;
import 'dart:ui';
import 'package:vector_math/vector_math.dart';

class IsoBoxRenderOptions {
  final Color edgeColor;
  final double edgeWidth;
  final Color topColor;
  final Color frontColor;
  final Color sideColor;
  final bool drawEdges;
  final bool fillSides;
  final double isoScale;

  const IsoBoxRenderOptions({
    this.edgeColor = const Color(0xFF000000),
    this.edgeWidth = 1.0,
    this.topColor = const Color(0xFFCCCCCC),
    this.frontColor = const Color(0xFFAAAAAA),
    this.sideColor = const Color(0xFF888888),
    this.drawEdges = true,
    this.fillSides = true,
    this.isoScale = 1.0,
  });
}

Offset isoProject(Vector3 p, {required Offset originOffset, double isoScale = 1.0}) {
  final double sx = (p.x - p.z) * 0.5 * isoScale;
  final double sy = (p.x + p.z) * 0.25 * isoScale - p.y * isoScale;
  return originOffset + Offset(sx, sy);
}

void renderIsoBox({
  required Canvas canvas,
  required Vector3 start,
  required Vector3 end,
  Offset originOffset = Offset.zero,
  Color edgeColor = const Color(0xFF000000),
  double edgeWidth = 1.0,
  Color topColor = const Color(0xFFCCCCCC),
  Color frontColor = const Color(0xFFAAAAAA),
  Color sideColor = const Color(0xFF888888),
  bool drawEdges = true,
  bool fillSides = false,
  double isoScale = 1.0,
}) {
  final double minX = start.x < end.x ? start.x : end.x;
  final double maxX = start.x > end.x ? start.x : end.x;
  final double minY = start.y < end.y ? start.y : end.y;
  final double maxY = start.y > end.y ? start.y : end.y;
  final double minZ = start.z < end.z ? start.z : end.z;
  final double maxZ = start.z > end.z ? start.z : end.z;

  final List<Vector3> v = [
    Vector3(minX, minY, minZ),
    Vector3(maxX, minY, minZ),
    Vector3(maxX, maxY, minZ),
    Vector3(minX, maxY, minZ),
    Vector3(minX, minY, maxZ),
    Vector3(maxX, minY, maxZ),
    Vector3(maxX, maxY, maxZ),
    Vector3(minX, maxY, maxZ),
  ];

  final List<Offset> p = v.map((vv) => isoProject(vv, originOffset: originOffset, isoScale: isoScale)).toList();

  final List<_Face> faces = [
    _Face(indices: [2, 3, 7, 6], color: topColor, depth: (v[2].y + v[3].y + v[7].y + v[6].y) / 4),
    _Face(indices: [0, 1, 2, 3], color: frontColor, depth: (v[0].z + v[1].z + v[2].z + v[3].z) / 4),
    _Face(indices: [5, 4, 7, 6], color: frontColor.withAlpha((frontColor.alpha * 0.9).toInt()), depth: (v[5].z + v[4].z + v[7].z + v[6].z) / 4),
    _Face(indices: [1, 5, 6, 2], color: sideColor, depth: (v[1].x + v[5].x + v[6].x + v[2].x) / 4),
    _Face(indices: [4, 0, 3, 7], color: sideColor.withAlpha((sideColor.alpha * 0.95).toInt()), depth: (v[4].x + v[0].x + v[3].x + v[7].x) / 4),
  ];

  faces.sort((a, b) => a.depth.compareTo(b.depth));

  final Paint fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint edgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = edgeColor
    ..strokeWidth = edgeWidth
    ..strokeJoin = StrokeJoin.round;

  for (final face in faces) {
    final path = Path();
    final first = p[face.indices[0]];
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < face.indices.length; i++) {
      final pt = p[face.indices[i]];
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();

    if (fillSides) {
      fillPaint.color = face.color;
      canvas.drawPath(path, fillPaint);
    }
    if (drawEdges) {
      canvas.drawPath(path, edgePaint);
    }
  }

  if (drawEdges) {
    final List<List<int>> edges = [
      [0,1],[1,2],[2,3],[3,0],
      [4,5],[5,6],[6,7],[7,4],
      [0,4],[1,5],[2,6],[3,7],
    ];
    for (final e in edges) {
      final a = p[e[0]];
      final b = p[e[1]];
      canvas.drawLine(a, b, edgePaint);
    }
  }
}

class _Face {
  final List<int> indices;
  final Color color;
  final double depth;
  _Face({required this.indices, required this.color, required this.depth});
}

void drawIsometricBox(
    Canvas canvas,
    Vector3 aabbMin,
    Vector3 aabbMax, {
      double scale = 16.0,
      Offset offset = Offset.zero,
      Paint? topPaint,
      Paint? leftPaint,
      Paint? rightPaint,
      Paint? edgePaint,
      double strokeWidthForEdges = 1.5,
    }) {
  topPaint ??= Paint()..style = PaintingStyle.fill..color = const Color(0x80CCCCCC);
  leftPaint ??= Paint()..style = PaintingStyle.fill..color = const Color(0x60999999);
  rightPaint ??= Paint()..style = PaintingStyle.fill..color = const Color(0x60999999);
  edgePaint ??= Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidthForEdges
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..color = const Color(0xFF000000);

  final double sin30 = 0.5;
  final double cos30 = math.sqrt(3) / 2.0;

  Offset projectIso(Vector3 p) {
    final dx = (p.x - p.z) * cos30 * scale;
    final dy = -p.y * scale + (p.x + p.z) * sin30 * scale;
    return Offset(dx, dy) + offset;
  }

  List<Vector3> corners = List<Vector3>.generate(8, (i) {
    final double x = (i & 1) == 0 ? aabbMin.x : aabbMax.x;
    final double y = (i & 2) == 0 ? aabbMin.y : aabbMax.y;
    final double z = (i & 4) == 0 ? aabbMin.z : aabbMax.z;
    return Vector3(x, y, z);
  });

  final List<List<int>> edges = [
    [0, 1], [2, 3], [4, 5], [6, 7],
    [0, 2], [1, 3], [4, 6], [5, 7],
    [0, 4], [1, 5], [2, 6], [3, 7],
  ];

  final List<int> topFace = [5, 7, 3, 1];
  final List<int> leftFace = [0, 2, 6, 4];
  final List<int> rightFace = [1, 3, 7, 5];

  double faceDepthAverage(List<int> face) {
    double s = 0.0;
    for (var idx in face) {
      s += corners[idx].x + corners[idx].z;
    }
    return s / face.length;
  }

  final faces = <Map<String, dynamic>>[
    {'indices': topFace, 'paint': topPaint},
    {'indices': leftFace, 'paint': leftPaint},
    {'indices': rightFace, 'paint': rightPaint},
  ];

  faces.sort((a, b) => faceDepthAverage(a['indices']).compareTo(faceDepthAverage(b['indices'])));

  for (final face in faces) {
    final List<int> indexes = List<int>.from(face['indices']);
    final Paint p = face['paint'] as Paint;
    final Path poly = Path();
    for (int i = 0; i < indexes.length; i++) {
      final off = projectIso(corners[indexes[i]]);
      if (i == 0) {
        poly.moveTo(off.dx, off.dy);
      } else {
        poly.lineTo(off.dx, off.dy);
      }
    }
    poly.close();
    canvas.drawPath(poly, p);
  }

  for (final e in edges) {
    final p0 = projectIso(corners[e[0]]);
    final p1 = projectIso(corners[e[1]]);
    canvas.drawLine(p0, p1, edgePaint);
  }
}
