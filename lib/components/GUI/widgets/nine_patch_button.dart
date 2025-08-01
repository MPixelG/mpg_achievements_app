import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_widgets.dart';

import 'nine_patch_material.dart';

class NinePatchButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  late final NinePatchPainter painter;

  NinePatchButton({
    super.key,
    required this.text,
    required this.onPressed,
    String textureName = "button_0",
  }){
    painter = NinePatchPainter(NinePatchTexture.loadFromCache("button_0"));
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