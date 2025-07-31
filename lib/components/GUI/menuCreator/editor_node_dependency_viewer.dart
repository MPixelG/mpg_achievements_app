import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';

class NodeViewer extends StatefulWidget {
  final LayoutWidget? root;

  const NodeViewer({this.root, super.key});

  @override
  State<NodeViewer> createState() => _NodeViewerState();
}

class _NodeViewerState extends State<NodeViewer> {
  void _handleReorder(LayoutWidget dragged, LayoutWidget target) {
    if (widget.root == null || dragged == target || isDescendant(dragged, target)) return;

    final parent = findParent(widget.root!, dragged);
    parent?.children.remove(dragged);

    target.children.add(dragged);
    setState(() {});
  }

  bool isDescendant(LayoutWidget dragged, LayoutWidget target) {
    for (var child in dragged.children) {
      if (child == target || isDescendant(child, target)) return true;
    }
    return false;
  }

  LayoutWidget? findParent(LayoutWidget root, LayoutWidget child) {
    for (var c in root.children) {
      if (c == child) return root;
      final found = findParent(c, child);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.root == null) {
      return const Center(child: Text("No root widget defined"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Node Viewer"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: DisplayNode(
          node: widget.root!,
          onReorder: _handleReorder,
        ),
      ),
    );
  }
}

// In DisplayNode
class DisplayNode extends StatelessWidget {
  final LayoutWidget node;
  final String prefix;
  final String childrenPrefix;
  final void Function(LayoutWidget dragged, LayoutWidget target)? onReorder;

  const DisplayNode({
    required this.node,
    super.key,
    this.prefix = "",
    this.childrenPrefix = "",
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final children = node.children;

    List<Widget> displayedChildren = [];
    for (int i = 0; i < children.length; i++) {
      String nextPrefix = childrenPrefix + (i == children.length - 1 ? "└── " : "├── ");
      String nextChildrenPrefix = childrenPrefix + (i == children.length - 1 ? "    " : "│   ");

      displayedChildren.add(
        DisplayNode(
          node: children[i],
          prefix: nextPrefix,
          childrenPrefix: nextChildrenPrefix,
          onReorder: onReorder,
          key: ValueKey(children[i].id),
        ),
      );
    }

    return DragTarget<LayoutWidget>(
      onWillAccept: (dragged) {
        return dragged != node && !(dragged == null || isDescendant(dragged, node));
      },
      onAccept: (dragged) {
        if (onReorder != null) onReorder!(dragged, node);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<LayoutWidget>(
          data: node,
          feedback: Material(
            child: Text(prefix + node.id, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$prefix${node.id}",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(children: displayedChildren),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool isDescendant(LayoutWidget dragged, LayoutWidget target) {
    if (target.children.contains(dragged)) return true;
    for (var child in target.children) {
      if (isDescendant(dragged, child)) return true;
    }
    return false;
  }
}

