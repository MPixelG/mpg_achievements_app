import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_action_registry.dart';

class EditorMenuBar extends StatelessWidget {

  const EditorMenuBar({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: MenuBar(
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.fromLTRB(8, 4, 8, 4)),
        fixedSize: WidgetStatePropertyAll(Size.fromWidth(MediaQuery.of(context).size.width)),
        elevation: const WidgetStatePropertyAll(0),
        visualDensity: VisualDensity.compact,
        shape: WidgetStatePropertyAll(BeveledRectangleBorder(borderRadius: BorderRadius.circular(2))),
        backgroundColor: WidgetStatePropertyAll(Colors.black38.withAlpha(220)),
      ),
      children: MenuActionRegistry.getAllAsMenuBarItems(),
    ),
  );
}
