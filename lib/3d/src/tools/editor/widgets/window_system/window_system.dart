import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_container.dart';

class WindowManager extends StatelessWidget {
  final WindowManagerController controller;

  const WindowManager({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, _) => _buildNode(controller.rootNode));

  Widget _buildNode(WindowNode node) {
    if (node is WindowLeaf) {
      return WindowPane(
        config: node.config,
        node: node,
        onSwap: (newConfig) {
          controller.replaceNode(node, WindowLeaf(config: newConfig));
        },
        onSplit: (direction) {
          controller.replaceNode(
            node,
            WindowSplit(
              direction: direction,
              children: [
                WindowLeaf(config: node.config),
                WindowLeaf(config: node.config),
              ],
            ),
          );
        },
      );
    }

    if (node is WindowSplit) {
      return ResizableContainer(
        direction: node.direction,
        children: node.children.map<ResizableChild>((val) => ResizableChild(child: _buildNode(val))).toList(),
      );
    }

    return const SizedBox.shrink();
  }
}

class WindowManagerController extends ChangeNotifier {
  WindowNode rootNode;

  WindowManagerController(this.rootNode);

  void replaceNode(WindowNode oldNode, WindowNode newNode) {
    rootNode = _replaceInTree(rootNode, oldNode, newNode);
    notifyListeners();
  }

  WindowNode _replaceInTree(WindowNode current, WindowNode target, WindowNode replacement) {
    if (current == target) return replacement;

    if (current is WindowSplit) {
      return WindowSplit(direction: current.direction, children: current.children.map((c) => _replaceInTree(c, target, replacement)).toList());
    }

    return current;
  }
}
