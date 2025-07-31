import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';

class NodeViewer extends StatefulWidget { // a widget to view and manage a tree of LayoutWidgets
  final LayoutWidget? root; // the root node of the tree to display

  const NodeViewer({this.root, super.key}); //default constructor with an optional root node

  @override
  State<NodeViewer> createState() => NodeViewerState(); // create the state for this widget. we have a separate class for that
}

class NodeViewerState extends State<NodeViewer> { //the state for the NodeViewer widget
  void _handleReorder(LayoutWidget dragged, LayoutWidget target) { //handle the reordering of nodes when a widget is dragged and dropped onto another
    if (widget.root == null ||//if there is no root node, do nothing
        dragged == target || //if the dragged widget is the same as the target, do nothing
        isDescendant(dragged, target)) { //if the dragged widget is a descendant (a child / grand child / ...) of the target, do nothing
      return;
    }

    final parent = findParent(widget.root!, dragged); //get the parent of the dragged widget
    parent?.children.remove(dragged); //remove the dragged widget from its parent

    target.children.add(dragged); //and add it to the target widgets children
    setState(() {}); //refresh the state to update the gui
  }

  bool isDescendant(LayoutWidget dragged, LayoutWidget target) { //check if the dragged widget is a descendant of the target widget
    for (var child in dragged.children) { //for every child of the dragged widget
      if (child == target || isDescendant(child, target)) return true; //if the child is the target or if the child has the target as a descendant, return true. this checks the entire tree of children recursively
    }
    return false; //if no child is the target or has the target as a descendant, return false
  }

  LayoutWidget? findParent(LayoutWidget root, LayoutWidget child) { //find the parent of a child widget in the tree
    for (var c in root.children) { //for every child of the root widget
      if (c == child) return root; //if the child is the same as the current child, return the root widget as the parent
      final found = findParent(c, child); //if thats not the case, repeat the process for the current child
      if (found != null) return found; //if the child was found in the current child, return it
    }
    return null; //if the child was not found in any of the children, return null
  }

  @override
  Widget build(BuildContext context) { //build the widget tree for the NodeViewer
    if (widget.root == null) { //if there is no root widget, display a message
      return const Scaffold(
        body: Center(child: Text("No root widget defined")), // display that no root widget is defined
      );
    }

    return Scaffold( //the main scaffold for the NodeViewer
      appBar: AppBar( //the app bar at the top of the screen
        title: const Text("Node Viewer"), //with a title
        centerTitle: true, //that is centered
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, //the background color is the inversed scheme
      ),

      //trash to drop widgets
      floatingActionButton: DragTarget<LayoutWidget>( //the floating action button is a preset we use for a trash can. DragTarget allows us to drop widgets onto it
        builder: (context, candidateData, rejectedData) => FloatingActionButton( //set a floating action button as a child so that we can drop widgets onto it and click it to clear the tree
          onPressed: () { //when the button is pressed
            widget.root!.children.clear(); //clear the children of the root widget
            setState(() {}); //and refresh the state to update the gui
          },
          child: Icon(CupertinoIcons.trash), //the icon of the button is a trash can
        ),
        onAcceptWithDetails: (details) { //when a widget is dropped onto the button
          details.data.removeFromParent(details.data); //we remove the widget from its parent so that its gone
          setState(() {}); //and refresh the state to update the gui
        },
      ),

      body: Container( //the actual body of the NodeViewer
        padding: const EdgeInsets.all(16), //padding around the content so that it doesnt touch the edges
        child: InteractiveViewer( //allows us to zoom and move the content
          constrained: false, //we dont want to constrain the size of the content
          boundaryMargin: const EdgeInsets.all(10), //the margin around the content so that we can scroll a bit outside the content
          minScale: 0.4, //the minimum scale we can zoom out to
          maxScale: 8.0, //the maximum scale we can zoom in to
          child: SingleChildScrollView( //allows to scroll horizontally
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView( //and vertically
              scrollDirection: Axis.vertical,
              child: Container( //the container that holds the content
                constraints: const BoxConstraints( //with constraints so that it has a minimum size
                  minWidth: 800, //of 800
                  minHeight: 600, //and 600
                ),
                child: DisplayNode( //the actual display node. it also displays all the children recursively
                  node: widget.root!, //the root widget is the node we want to display
                  onReorder: _handleReorder, //the function to handle reordering of nodes when they are dragged and dropped onto each other
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
      String nextPrefix =
          childrenPrefix + (i == children.length - 1 ? "└── " : "├── ");
      String nextChildrenPrefix =
          childrenPrefix + (i == children.length - 1 ? "    " : "│   ");

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
        return dragged.data != node && node.canAddChild;
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

  Widget _buildNodeContent(
    BuildContext context,
    bool isHovering,
    List<Widget> displayedChildren,
  ) {
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
                  Icon(Icons.widgets, size: 16, color: Colors.blue.shade700),
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
}
