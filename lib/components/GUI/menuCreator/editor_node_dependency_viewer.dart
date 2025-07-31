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
      return const Scaffold(
        body: Center(child: Text("No root widget defined")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Node Viewer"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 2.0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 800,
                  minHeight: 600,
                ),
                child: DisplayNode(
                  node: widget.root!,
                  onReorder: _handleReorder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
      onWillAcceptWithDetails: (dragged) {
        return dragged.data != node && !(isDescendant(dragged.data, node));
      },
      onAcceptWithDetails: (dragged) {
        if (onReorder != null) onReorder!(dragged.data, node);
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;

        return Draggable<LayoutWidget>(
          data: node,
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: Text(
                prefix + node.id,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildNodeContent(context, isHovering, displayedChildren),
          ),
          child: _buildNodeContent(context, isHovering, displayedChildren),
        );
      },
    );
  }

  Widget _buildNodeContent(BuildContext context, bool isHovering, List<Widget> displayedChildren) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isHovering ? Colors.green.shade50 : Colors.transparent,
        border: isHovering
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.widgets,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$prefix${node.id}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            if (displayedChildren.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: displayedChildren,
                ),
              ),
            ],
          ],
        ),
      ),
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