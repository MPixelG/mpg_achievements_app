import 'package:flutter/material.dart';

import 'menu_bar_button.dart';

class EditorMenuBar extends StatelessWidget {
  final List<MenuBarButton> menuBarButtons;
  const EditorMenuBar({super.key, required this.menuBarButtons});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.widthOf(context),
    height: 32,
    child: Align(
      alignment: AlignmentGeometry.topCenter,
      child: MenuBar(
        style: MenuStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(0, 0, 0, 3)),
          fixedSize: WidgetStatePropertyAll(Size.fromWidth(MediaQuery.widthOf(context))),
          elevation: const WidgetStatePropertyAll(0),
          visualDensity: VisualDensity.compact,
          shape: WidgetStatePropertyAll(BeveledRectangleBorder(borderRadius: BorderRadiusGeometry.circular(2))),
          backgroundColor: WidgetStatePropertyAll(Colors.black38.withAlpha(160)),
        ),
        children: menuBarButtons,
      ),
    ),
  );
}
