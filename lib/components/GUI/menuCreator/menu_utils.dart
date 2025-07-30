import 'dart:ui';

import 'editable_widget_2.dart';

void collectAllNodesRecursive(EditorNode node, List<EditorNode> allNodes) { //recursively collects all of the child nodes into a given list.
    allNodes.add(node); //puts the current node into the list
    for (EditorNode child in node.childrenNodes) { //repeats that process for every child.
      collectAllNodesRecursive(child, allNodes);
    }
  }

  Offset getAbsolutePosition(EditableWidget widget, EditorNode node) { //returns the absolute position of a given node. this differences because the position of a child node is the position of the parent + the position of the child.
    Offset absolutePos = Offset.zero; //initialize with zero
    EditorNode? currentNode = node; //set the node to the given one

    while (currentNode != null) { //repeat until its null so we arrived at the root node. (the first node where every other node comes out of)
      final nodePos = currentNode.properties['position'] as Offset? ?? Offset(0.1, 0.1); //get the position out of the properties
      absolutePos = Offset(
        absolutePos.dx + nodePos.dx, //add it to the current pos
        absolutePos.dy + nodePos.dy, //same for y
      );
      currentNode = findParent(widget, currentNode); //and repeat the process with the parent
    }

    return absolutePos; //return it
  }

  EditorNode? findParent(EditableWidget widget, EditorNode targetNode) { //returns the parent of a given editor node. since the editor nodes dont have parents but only children we have to iterate over every one of them.
    return _findParentRecursive(widget.node, targetNode);
  }

  EditorNode? _findParentRecursive(EditorNode current, EditorNode target) { // a recursive function to iterate over every child node and get the node that has the given node as a child
    for (EditorNode child in current.childrenNodes) { //iterate over every child
      if (child == target) { //if it has the targeted node as a child we found our parent!
        return current;
      }
    }
    //if we didnt find our parent, we have to do the same with every one of the children
    for (EditorNode child in current.childrenNodes) { //iterate over every child again
      final result = _findParentRecursive(child, target); // repeat the process
      if (result != null) return result; //if we got a valid result. we return it to the top
    }

  return null; //return null if there is no node with the given node as a parent
}