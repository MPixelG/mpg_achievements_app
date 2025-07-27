import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class EditableWidget extends StatefulWidget {
  final EditorNode node;
  final bool isRoot;

  const EditableWidget(this.node, {super.key, this.isRoot = false});

  @override
  State<StatefulWidget> createState() => _EditableWidgetState();
}

class _EditableWidgetState extends State<EditableWidget> {

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  @override
  Widget build(BuildContext context) {
    if (widget.isRoot) {
      List<EditorNode> allNodes = [];
      _collectAllNodesRecursive(widget.node, allNodes);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (EditorNode node in allNodes)
            _buildNodeWidget(node),
        ],
      );
    } else {
      return Container();
    }
  }

  void _collectAllNodesRecursive(EditorNode node, List<EditorNode> allNodes) {
    allNodes.add(node);
    for (EditorNode child in node.childrenNodes) {
      _collectAllNodesRecursive(child, allNodes);
    }
  }

  Offset _getAbsolutePosition(EditorNode node) {
    Offset absolutePos = Offset.zero;
    EditorNode? currentNode = node;

    while (currentNode != null) {
      final nodePos = currentNode.properties['position'] as Offset? ?? Offset(0.1, 0.1);
      absolutePos = Offset(
        absolutePos.dx + nodePos.dx,
        absolutePos.dy + nodePos.dy,
      );
      currentNode = _findParent(currentNode);
    }

    return absolutePos;
  }

  EditorNode? _findParent(EditorNode targetNode) {
    return _findParentRecursive(widget.node, targetNode);
  }

  EditorNode? _findParentRecursive(EditorNode current, EditorNode target) {
    for (EditorNode child in current.childrenNodes) {
      if (child == target) {
        return current;
      }
    }

    for (EditorNode child in current.childrenNodes) {
      final result = _findParentRecursive(child, target);
      if (result != null) return result;
    }

    return null;
  }

  Widget _buildNodeWidget(EditorNode node) {
    final absolutePos = _getAbsolutePosition(node);
    final isDragging = node.properties['isDragging'] as bool? ?? false;

    Widget content = Container(
      decoration: BoxDecoration(
        border: isDragging ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: node.builder(),
    );

    return Positioned(
      left: absolutePos.dx * screenWidth,
      top: absolutePos.dy * screenHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          setState(() {
            node.properties['isDragging'] = true;
          });
        },
        onPanUpdate: (details) {
          final currentPos = node.properties['position'] as Offset? ?? Offset(0.1, 0.1);
          final newPos = Offset(
            currentPos.dx + details.delta.dx / screenWidth,
            currentPos.dy + details.delta.dy / screenHeight,
          );
          setState(() {
            node.properties['position'] = newPos.clamp(Offset(-0.5, -0.5), Offset(1.5, 1.5));
          });
        },
        onPanEnd: (details) {
          setState(() {
            node.properties['isDragging'] = false;
          });
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition, node);
        },
        child: content,
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position, EditorNode targetNode) async {
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(value: 'add_child', child: Text('Add Child')),
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
        PopupMenuItem(value: 'info', child: Text('Show Info')),
      ],
    );

    if (selected == 'add_child') {
      setState(() {
        final childPos = Offset(0.05, 0.05);

        final newChild = EditorNode(() => Container(
          width: 50,
          height: 30,
          color: Colors.primaries.random(Random(widget.key.hashCode)).shade300,
        ), properties: {'position': childPos});

        targetNode.childrenNodes.add(newChild);
      });
    } else if (selected == 'info') {
      final parent = _findParent(targetNode);
      final absolutePos = _getAbsolutePosition(targetNode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parent: ${parent != null ? "Yes" : "Root"}, AbsPos: ${absolutePos.dx.toStringAsFixed(2)}, ${absolutePos.dy.toStringAsFixed(2)}')),
      );
    }
  }

  Color _getRandomColor() {
    final colors = [Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)].withValues(alpha: 0.7);
  }
}

extension OffsetClamp on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(
      dx.clamp(min.dx, max.dx),
      dy.clamp(min.dy, max.dy),
    );
  }
}

class EditorNode {
  Map<String, dynamic> properties;
  List<EditorNode> childrenNodes = [];
  final Widget Function() builder;

  EditorNode(this.builder, {required this.properties});
}