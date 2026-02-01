import 'package:flutter/material.dart';

class MenuBarButton extends StatelessWidget {
  final Widget child;
  final void Function() onPressed;

  const MenuBarButton({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed, 
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(Colors.black38.withAlpha(160)),
      elevation: const WidgetStatePropertyAll(0),
      foregroundColor: const WidgetStatePropertyAll(Colors.white70),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          color: Colors.white70,
          decorationColor: Colors.white10,
        ),
      ),
      shape: WidgetStatePropertyAll(
        BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
      enableFeedback: false,
      overlayColor: const WidgetStatePropertyAll(Colors.white12),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
    ),
    child: child,
  );
}