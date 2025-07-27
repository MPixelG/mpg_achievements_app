import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

class PreviewWidget extends StatelessWidget {//for the visible stuff
  final PreviewNode node;

  final VoidCallback? onDelete;
  final void Function(PreviewNode)? onRemoveChild;

  const PreviewWidget({super.key, required this.node, this.onDelete, this.onRemoveChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: node.maxSize.width * MediaQuery.of(context).size.width,
      height: node.maxSize.height * MediaQuery.of(context).size.height,
      color: Colors.amber.withValues(alpha: .2),
      child: Stack(
        children: [
          for (final child in node.children)
            Stack(
              children: [
                Positioned(
                  left: node.position.x * MediaQuery.of(context).size.width,
                  top: node.position.y * MediaQuery.of(context).size.height,
                  child: PreviewWidget(
                    node: child,
                    onRemoveChild: (c) {
                      onRemoveChild?.call(c);
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 16),
                    onPressed: () {
                      onRemoveChild?.call(child);
                    },
                  ),
                ),
              ],
            ),
          GestureDetector(onSecondaryTapDown: (details) => _showContextMenu(context, (node.position..multiply(MediaQuery.of(context).size.toVector2())).toOffset(), onRemoveChild))
        ],
      ),
    );
  }


  void _showContextMenu(BuildContext context, Offset position,
      Function(PreviewNode node)? onDelete) async {
    final menu = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Text('Delete'),
          onTap: () => onDelete?.call(node),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Text('Edit'),
        ),
      ],
    );
  }
}

class PreviewNode { //for the logic
  Size get size{
    double? width = properties["width"].toDouble();
    double? height = properties["height"].toDouble();

    return Size(width ?? 0.1, height ?? 0.1);
  }

  Vector2 get position{

    double? x = properties["x"].toDouble();
    double? y = properties["y"].toDouble();

    return Vector2(x ?? 0.5, y ?? 0.1);

  }

  String type;

  Map<String, dynamic> properties = {"width": 0.15, "height": 0.1, "x": 0.5, "y": 0.2};

  List<PreviewNode> children;

  PreviewNode({this.children = const [], this.type = "Button"});

  Size get maxSize {
    double maxX = size.width;
    double maxY = size.height;

    for (final c in children) {
      final s = c.maxSize;
      maxX = max(maxX, s.width);
      maxY = max(maxY, s.height);
    }

    return Size(maxX, maxY);
  }



}
