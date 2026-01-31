import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/menuBar/menu_bar_button.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/logic_nodes.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_system.dart';

///Editor overlay with Window System
class Editor3DOverlay extends StatelessWidget {
  final String id;

  const Editor3DOverlay({required this.id, super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const EditorMenuBar(
        menuBarButtons: [
          MenuBarButton(child: Text("test1")),
          MenuBarButton(child: Text("test2")),
          MenuBarButton(child: Text("test3")),
        ],
      ),
      SizedBox(width: MediaQuery.widthOf(context), height: MediaQuery.heightOf(context) - 33, child: getEditorController(id).windowManager),
    ],
  ); //uses the window manager of the controller as the widget to show. this way we dont cache widgets directly and dont use states either
}

//the EditorController class. Acts basically as a state for the Editor Overlay. we cant use a state because otherwise the state would get deleted when we hide the Overlay
class EditorController {
  final WindowManager windowManager = WindowManager(
    controller: WindowManagerController(
      loadNodeFromJson({
        "windowType": "windowSplit",
        "proportions": [0.25, 0.75],
        "direction": "horizontal",
        "children": [
          {
            "windowType": "windowLeaf",
            "config": {"id": "test1"},
          },
          {
            "windowType": "windowSplit",
            "proportions": [0.5, 0.5],
            "direction": "vertical",
            "children": [
              {
                "windowType": "windowLeaf",
                "config": {"id": "test1"},
              },
              {
                "windowType": "windowLeaf",
                "config": {"id": "test2"},
              },
            ],
          },
        ],
      }),
    ),
  );
}

final Map<String, EditorController> _controllers = {};

///returns an editor controller for a given id. if there isn't one yet, it gets created
EditorController getEditorController(String id) => _controllers[id] ??= EditorController();
