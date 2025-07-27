import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DesignNode  {
  final String id;
  final String type;
  final Map<String, dynamic> properties;
  final List<DesignNode> children;


  DesignNode({
    required this.id,
    required this.type,
    this.properties = const {},
    this.children = const [],
  });

  factory DesignNode.fromJson(Map<String, dynamic> json) {
    return DesignNode(
      id: json['id'],
      type: json['type'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => DesignNode.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'properties': properties,
    'children': children.map((e) => e.toJson()).toList(),
  };


}

Widget buildWidgetFromNode(DesignNode node) {
  final children = node.children.map(buildWidgetFromNode).toList();

  switch (node.type) {
    case 'Column':
      return Column(
        mainAxisAlignment: parseMainAxis(node.properties['mainAxisAlignment']),
        crossAxisAlignment: parseCrossAxis(node.properties['crossAxisAlignment']),
        children: children,
      );
    case 'Container':
      return Container(
        padding: EdgeInsets.all(8),
        child: children.isNotEmpty ? children.first : null,
      );
    case 'Button':
      return ElevatedButton(
        onPressed: () {
          print("Action: ${node.properties['action']}");
        },
        child: Text(node.properties['text'] ?? 'Button'),
      );
    default:
      return Text("Unknown: ${node.type}");
  }
}

MainAxisAlignment parseMainAxis(String? value) {
  switch (value) {
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'end':
      return MainAxisAlignment.end;
    default:
      return MainAxisAlignment.start;
  }
}

CrossAxisAlignment parseCrossAxis(String? value) {
  switch (value) {
    case 'center':
      return CrossAxisAlignment.center;
    case 'end':
      return CrossAxisAlignment.end;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    default:
      return CrossAxisAlignment.start;
  }
}


class DesignPreview extends StatelessWidget {
  final DesignNode root;

  const DesignPreview({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return buildWidgetFromNode(root);
  }
}

class EditableDesignNode extends StatelessWidget {
  final DesignNode node;
  final void Function(DesignNode droppedChild)? onChildDropped;

  const EditableDesignNode({
    super.key,
    required this.node,
    this.onChildDropped,
  });

  @override
  Widget build(BuildContext context) {
    final children = node.children.map(
          (child) => EditableDesignNode(
        node: child,
        onChildDropped: (dropped) {
          // z. B. Kind in Container einfügen
          child.children.add(dropped);
        },
      ),
    ).toList();

    final display = buildWidgetFromNode(node);

    return DragTarget<DesignNode>(
      onWillAccept: (data) => true,
      onAccept: (childNode) {
        onChildDropped?.call(childNode);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            Draggable<DesignNode>(
              data: node,
              feedback: Opacity(opacity: 0.7, child: display),
              child: display,
            ),
          ],
        );
      },
    );
  }
}


class EditorCanvas extends StatefulWidget {
  final List<DesignNode> nodes;

  const EditorCanvas({super.key, required this.nodes});

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  void _addButton() {
    setState(() {
      widget.nodes.add(
        DesignNode(
          id: "btn_${DateTime.now().millisecondsSinceEpoch}",
          type: "Button",
          properties: {"text": "New"},
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ...widget.nodes.map(
              (node) => EditableDesignNode(
            node: node,
            onChildDropped: (dropped) {
              setState(() {
                node.children.add(dropped);
              });
            },
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _addButton,
            child: Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

