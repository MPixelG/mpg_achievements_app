import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';

class NodeViewer extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _NodeViewerState();

  NodeViewer({this.root, super.key});

  LayoutWidget? root;
}

class _NodeViewerState extends State<NodeViewer> {

  void handleReorder(LayoutWidget dragged, LayoutWidget target) {
    if (dragged == target || isDescendant(dragged, target)) return;

    final parent = findParent(widget.root!, dragged);
    parent?.removeChild(dragged);

    target.addChild(dragged);

    setState(() {});
  }


  bool isDescendant(LayoutWidget dragged, LayoutWidget target) {
    for (var child in (dragged).children) {
      if (child == target) return true;
      if (isDescendant(child, target)) return true;
    }
      return false;
  }
  LayoutWidget? findParent(LayoutWidget root, LayoutWidget child) {
    for (var c in root.children) {
      if (c == child) return root;
      var result = findParent(c, child);
      if (result != null) return result;
        }
    return null;
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> dependencies = [];

    if (widget.root == null) {
      return Center(child: Text("No root widget defined"));
    }else{

      for (var value in widget.root!.children) {
        buildNodeDependencies(value, dependencies);
      }

      if (dependencies.isEmpty) {
        return Center(child: Text("No dependencies found"));
      }
    }

    return Scaffold(
      backgroundColor: CupertinoColors.lightBackgroundGray,
      appBar: AppBar(
        title: Text("Node Dependencies", textAlign: TextAlign.center),
        centerTitle: true,
        backgroundColor: CupertinoColors.inactiveGray,
        foregroundColor: CupertinoColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DisplayNode(
              node: widget.root!.build(context),
              onReorder: (dragged, target) => handleReorder(dragged as LayoutWidget, target as LayoutWidget),
            ),
          ],
        ),
      ),
    );

  }

  List<Widget> buildNodeDependencies(LayoutWidget widget, List<Widget> dependencies) {
    dependencies.add(Text(widget.build(context).toStringShort()));
    for (var child in widget.children) {
      buildNodeDependencies(child, dependencies);
    }
    return dependencies;
  }

}

List<Widget> extractChildren(Widget widget) {
  if (widget is SingleChildRenderObjectWidget) {
    if (widget.child != null) {
      return [widget.child!];
    }
  } else if (widget is MultiChildRenderObjectWidget) {
    return widget.children;
  }
  return [];
}

// In DisplayNode
class DisplayNode extends StatelessWidget {
  final Widget node;
  final String prefix;
  final String childrenPrefix;
  final void Function(Widget dragged, Widget target)? onReorder;

  const DisplayNode({
    required this.node,
    super.key,
    this.prefix = "",
    this.childrenPrefix = "",
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = extractChildren(node);
    final int amountOfChildren = children.length;

    List<Widget> displayedChildren = [];
    for (int i = 0; i < children.length; i++) {
      String nextPrefix = childrenPrefix + (i + 1 == amountOfChildren ? "└── " : "├── ");
      String nextChildrenPrefix = childrenPrefix + (i + 1 == amountOfChildren ? "    " : "│    ");
      displayedChildren.add(
        DisplayNode(
          node: children[i],
          prefix: nextPrefix,
          childrenPrefix: nextChildrenPrefix,
          onReorder: onReorder,
          key: ValueKey(children[i]),
        ),
      );
    }

    return DragTarget<Widget>(
      onWillAccept: (data) { data != node && onReorder != null; return true; },
      onAccept: (dragged) {
        print("accepted!");
        if (onReorder != null) {
          onReorder!(dragged, node);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<Widget>(
          data: node,
          feedback: Material(
            child: Text("$prefix${node.toStringShort()}", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$prefix${node.toStringShort()}",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: displayedChildren,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
