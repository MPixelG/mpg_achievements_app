import 'package:flutter/material.dart';

class EditorMenuBar extends StatelessWidget {
  final List<Widget> menuBarObjects;

  const EditorMenuBar({super.key, required this.menuBarObjects});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: MenuBar(
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.fromLTRB(8, 4, 8, 4),
        ),
        fixedSize: WidgetStatePropertyAll(
          Size.fromWidth(MediaQuery.of(context).size.width),
        ),
        elevation: const WidgetStatePropertyAll(0),
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(
          BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        backgroundColor: WidgetStatePropertyAll(
          Colors.black38.withAlpha(220),
        ),
      ),
      children: menuBarObjects,
    ),
  );
}