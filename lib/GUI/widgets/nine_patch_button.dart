import 'package:flutter/material.dart';

import 'nine_patch_material.dart';
import 'nine_patch_widgets.dart';

class NinePatchButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  final Widget? child;

  late final NinePatchPainter painter;

  NinePatchButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.child,
    String textureName = "button_0",
  }) {
    painter = NinePatchPainter(NinePatchTexture.loadFromCache(textureName));
  }

  @override
  State<NinePatchButton> createState() => _NinePatchButtonState();
}

class _NinePatchButtonState extends State<NinePatchButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: CustomPaint(
        painter: widget.painter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
