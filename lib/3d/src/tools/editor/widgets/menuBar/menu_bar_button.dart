import 'package:flutter/material.dart';

class MenuBarButton extends StatelessWidget {
  final Widget child;

  const MenuBarButton({super.key, required this.child});

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () {
      print("pressed");
    },
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.black38.withAlpha(160)),
      elevation: const WidgetStatePropertyAll(0),
      textStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.white70, decorationColor: Colors.white10)),
      shape: WidgetStatePropertyAll(BeveledRectangleBorder(borderRadius: BorderRadiusGeometry.circular(2))),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
      enableFeedback: false,
      overlayColor: const WidgetStatePropertyAll(Colors.white12),
    ),
    child: child,
  );
}
