import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

class NinePatchButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final String imageName;
  final int borderX;
  final int borderY;
  final int borderX2;
  final int borderY2;

  const NinePatchButton({
    Key? key,
    required this.text,
    required this.onPressed, required this.imageName, required this.borderX, required this.borderY, required this.borderX2, required this.borderY2,
  }) : super(key: key);

  @override
  State<NinePatchButton> createState() => _NinePatchButtonState(imageName, borderX, borderY, borderX2, borderY2);
}

class _NinePatchButtonState extends State<NinePatchButton> {
  ui.Image? buttonImage;
  String imageName = "";

  final int borderX;
  final int borderY;
  final int borderX2;
  final int borderY2;

  _NinePatchButtonState(this.imageName, this.borderX, this.borderY, this.borderX2, this.borderY2);

  @override
  void initState() {
    super.initState();
    Flame.images.load('Menu/Buttons/$imageName.png').then((image) {
      setState(() {
        buttonImage = image;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (buttonImage == null) {
      return const SizedBox(width: 150, height: 80);
    }

    return GestureDetector(
      onTap: widget.onPressed,
      child: CustomPaint(
        painter: _NinePatchPainter(buttonImage!, 2, borderX, borderY, borderX2, borderY2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: Text(
              widget.text,
              style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: "gameFont"),
            ),
          ),
        )
      ),
    );
  }
}

class _NinePatchPainter extends CustomPainter {
  final ui.Image image;
  final int borderX;
  final int borderY;
  final int borderX2;
  final int borderY2;
  double scale = 2;

  _NinePatchPainter(this.image, [this.scale = 1, this.borderX = 2, this.borderY = 2, this.borderX2 = 3, this.borderY2 = 3]);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint();

    canvas.scale(scale);

    final dst = Rect.fromLTWH(0, 0, size.width / scale, size.height / scale);

    canvas.drawImageNine(
      image,
      Rect.fromLTWH(
        borderX.toDouble(),
        borderY.toDouble(),
        (image.width - 2 * borderX).toDouble(),
        (image.height - 3 * borderY).toDouble(),
      ),
      dst,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
