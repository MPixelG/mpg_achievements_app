
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_widgets.dart';

class NinePatchPainter extends CustomPainter {

  NinePatchTexture ninePatchTexture;

  double scale = 2;

  NinePatchPainter(this.ninePatchTexture);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint();

    canvas.scale(scale);

    final dst = Rect.fromLTWH(0, 0, size.width / scale, size.height / scale);

    canvas.drawImageNine(
      ninePatchTexture.texture!,
      Rect.fromLTWH(
        ninePatchTexture.borderX.toDouble(),
        ninePatchTexture.borderY.toDouble(),
        (ninePatchTexture.texture!.width - 2 * ninePatchTexture.borderX).toDouble(),
        (ninePatchTexture.texture!.height - 3 * ninePatchTexture.borderY).toDouble(),
      ),
      dst,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
