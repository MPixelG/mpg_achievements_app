import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_container.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';

///manager class for window panels
class WindowManager extends StatelessWidget {
  final WindowManagerController controller;

  const WindowManager({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: controller, builder: (_, _) => _buildNode(controller.rootNode));

  Widget _buildNode(WindowNode node) {
    if (node is WindowLeaf) {
      //the leaf nodes are shown as window panes
      return WindowPane(
        config: node.config,
        node: node,
        onSwap: (newConfig) {
          controller.replaceNode(node, WindowLeaf(config: newConfig)); // connecting the swap logic to the widget.
        },
        onDrop: (draggedNode, draggedConfig) {
          //and the drop logic too
          controller._swapNodes(draggedNode, node);
        },
        onSplit: (direction) {
          //on split we replace the node with a split variant with the old version as a child
          controller.replaceNode(
            node,
            WindowSplit(
              direction: direction, //the given direction
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
      //for the split windows we just use a resizable container with the children as Resizable Child Objects. this way you can resize your windows
      final proportions = node.proportions ?? List.filled(node.children.length, 1.0 / node.children.length);

      final ResizableController controller = ResizableController();
      final ResizableContainer container = ResizableContainer(
        direction: node.direction,
        children: List.generate(
          node.children.length,
          (index) => ResizableChild(
            size: ResizableSize.ratio(proportions[index]),
            child: _buildNode(node.children[index]),
            divider: const ResizableDivider(thickness: 8),
          ),
        ),
        controller: controller,
      );
      controller.addListener(() => onResizeContainer(container, node));

      return container;
    }

    return const SizedBox.shrink(); //for every other case (that shouldn't occur) we just use a sized box that is shrunk to fit in that space
  }

  void onResizeContainer(ResizableContainer container, WindowSplit node) {
    for (var element in container.children) {
      if (element.child is WindowPane) (element.child as WindowPane).updateHeaderWidth();
    }
    final double? firstRatio = container.controller?.ratios.first;
    if (firstRatio != 0.0 && firstRatio != 0.5) {
      node.proportions!.setRange(0, container.controller!.ratios.length, container.controller!.ratios);
    }
  }
}

//the WindowManagerController class. Acts basically as a state for the window manager. However we cant use a state because otherwise the state would get deleted when we hide the Overlay
class WindowManagerController extends ChangeNotifier {
  WindowNode rootNode;

  WindowManagerController(this.rootNode);

  ///replaces a given node with another given node. Uses recursion
  void replaceNode(WindowNode oldNode, WindowNode newNode) {
    rootNode = _replaceInTree(rootNode, oldNode, newNode);
    notifyListeners();
  }

  ///replaces a targeted node with a given replacement. helper function for [replaceNode]. Should not be called outside of [replaceNode]
  WindowNode _replaceInTree(WindowNode current, WindowNode target, WindowNode replacement) {
    if (current == target) return replacement;

    if (current is WindowSplit) {
      return WindowSplit(
        direction: current.direction,
        proportions: current.proportions,
        children: current.children.map((c) => _replaceInTree(c, target, replacement)).toList(),
      );
    }

    return current;
  }

  ///swaps the given node recursively.
  void _swapNodes(WindowNode node1, WindowNode node2) {
    if (node1 == node2) return; //if they are the same we dont swap.

    WindowConfig? config1;
    WindowConfig? config2;

    if (node1 is WindowLeaf) config1 = node1.config; //get the configs of the window nodes if they are leaf nodes
    if (node2 is WindowLeaf) config2 = node2.config;

    if (config1 != null && config2 != null) {
      //if one of the nodes wasn't a leaf node we dont swap
      rootNode = _swapInTree(rootNode, node1, node2, config1, config2);
      notifyListeners();
    }
  }

  ///recursive helper function for swapping 2 nodes
  WindowNode _swapInTree(WindowNode current, WindowNode target1, WindowNode target2, WindowConfig config1, WindowConfig config2) {
    if (current == target1) return WindowLeaf(config: config2);
    if (current == target2) return WindowLeaf(config: config1);

    if (current is WindowSplit) {
      return WindowSplit(
        direction: current.direction,
        proportions: current.proportions,
        children: current.children.map((c) => _swapInTree(c, target1, target2, config1, config2)).toList(),
      );
    }

    return current;
  }
}
