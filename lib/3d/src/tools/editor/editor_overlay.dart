import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar_button.dart';

class Editor3DOverlay extends StatefulWidget {
  const Editor3DOverlay({super.key});

  @override
  State<StatefulWidget> createState() => EditorOverlayState();
}

class EditorOverlayState extends State<Editor3DOverlay> {
  @override
  Widget build(BuildContext context) => const EditorMenuBar(
    menuBarButtons: [
      MenuBarButton(child: Text("test1")),
      MenuBarButton(child: Text("test2")),
      MenuBarButton(child: Text("test3")),
    ],
  );
}
