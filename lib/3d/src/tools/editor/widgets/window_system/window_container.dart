import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';
import 'package:uuid/uuid.dart';

import 'logic_nodes.dart';

///data of the swapped node and config of that node
class DragData {
  final WindowNode node;
  final WindowConfig config;

  const DragData({required this.node, required this.config});
}

const Uuid _uuid = Uuid();

///the window pane is the widget implementation of the [WindowLeaf] class, which only contains the logic. this is a wrapper for the child widget which also contains the drag n drop and swap logic.
class WindowPane extends StatefulWidget {
  final WindowConfig config; //the config of the shown content. contains data such as the title, the child widget, menu bar color, icon, etc.
  final WindowLeaf node; //the leaf node reference
  final Function(WindowConfig)? onSwap; // function that gets called if the window gets dragged on another window
  final Function(WindowNode draggedNode, WindowConfig draggedConfig)? onDrop; //function that gets called when another window is dropped ont this node
  final Function(Axis)? onSplit; // function that gets called when the window requests to get split.

  WindowPane({required this.config, required this.node, this.onSwap, this.onDrop, this.onSplit}) : super(key: GlobalObjectKey(_uuid.v4()));

  void updateHeaderWidth() {
    ((key as GlobalObjectKey<State<StatefulWidget>>).currentState as _WindowPaneState?)?._updateHeaderWidth();
  }

  @override
  State<WindowPane> createState() => _WindowPaneState();
}

///the state of the [WindowPane] class
class _WindowPaneState extends State<WindowPane> {
  bool _isHoveringHeader = false; //if the header is currently being hovered over
  final GlobalKey _headerKey = GlobalKey(); // the key of the header
  double _headerWidth = 200; // the width of the header

  ///updates the header width so that the width of the header is correct when dragged
  void _updateHeaderWidth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && mounted) {
        setState(() {
          //set the state to apply the update
          _headerWidth = renderBox.size.width;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateHeaderWidth();
  }

  @override
  void didUpdateWidget(WindowPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateHeaderWidth(); //since the widget updated the header width could be changed. so we update the width var
  }

  ///shows a menu with quick options for that window like splitting it or changing its type.
  void _showWindowMenu(BuildContext context, Offset tapPosition) {
    final RenderBox? renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      elevation: 0,
      color: Colors.black38,
      shape: BeveledRectangleBorder(borderRadius: BorderRadiusGeometry.circular(2)),
      position: RelativeRect.fromLTRB(tapPosition.dx, position.dy + renderBox.size.height, tapPosition.dx, position.dy + renderBox.size.height),
      items: [
        const PopupMenuItem(
          value: "change_type",
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: Colors.white60),
              SizedBox(width: 8),
              Text(
                "Change window type",
                style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "split_horizontally",
          child: Row(
            children: [
              Icon(Icons.horizontal_split, size: 18, color: Colors.white60),
              SizedBox(width: 8),
              Text(
                "Split horizontally",
                style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: "split_vertically",
          child: Row(
            children: [
              Icon(Icons.vertical_split, size: 18, color: Colors.white60),
              SizedBox(width: 8),
              Text(
                "Split vertically",
                style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == "change_type") {
        _showTypeSelector(context);
      } else if (value == "split_horizontally") {
        widget.onSplit?.call(Axis.vertical);
      } else if (value == "split_vertically") {
        widget.onSplit?.call(Axis.horizontal);
      }
    });
  }

  ///shows the window type selection menu
  void _showTypeSelector(BuildContext context) {
    final types = WindowTypeRegistry.getAll();
    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Window types registered!"), duration: Duration(seconds: 2)));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose your widow type"), //todo apply same style as the window quick actions
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final isCurrentType = widget.config.typeId == type.id;
              return ListTile(
                leading: Icon(type.icon),
                title: Text(type.title),
                selected: isCurrentType,
                selectedTileColor: Colors.blue.withAlpha(25),
                onTap: () {
                  Navigator.of(context).pop();
                  if (widget.onSwap != null && !isCurrentType) {
                    widget.onSwap!(WindowConfig.fromType(type.id));
                  }
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DragTarget<DragData>(
    onWillAcceptWithDetails: (details) => true,
    onAcceptWithDetails: (details) {
      // replace the node the node got dragged on to with the current one
      if (widget.onSwap != null) {
        widget.onDrop!(details.data.node, details.data.config);
      }
    },
    builder: (dragContext, candidateData, rejectedData) {
      //builder for the window
      final isHovering = candidateData.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          // header decoration
          border: Border.all(color: isHovering ? Colors.blue : Colors.grey.shade800, width: isHovering ? 2 : 1),
          color: const Color(0xFF1E1E1E),
        ),
        child: Column(
          //collum so that theres a header at the top and the content below
          children: [
            MouseRegion(
              //mouse region to detect hovering
              onEnter: (_) => setState(() => _isHoveringHeader = true),
              onExit: (_) => setState(() => _isHoveringHeader = false),
              child: GestureDetector(
                //and gestureDetector to detect clicking
                onTapDown: (details) => _showWindowMenu(dragContext, details.globalPosition),
                //on click we show the window option menu (split, change type, etc.)
                child: Draggable<DragData>(
                  //draggable so that it can be dragged
                  data: DragData(node: widget.node, config: widget.config), //the data that gets sent to the drag target when it gets dropped
                  feedback: Material(
                    //material for some design stuff
                    elevation: 8,
                    child: Container(
                      width: _headerWidth,
                      height: 32,
                      decoration: BoxDecoration(color: widget.config.headerColor ?? const Color(0xFF2D2D30), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          if (widget.config.icon != null) ...[Icon(widget.config.icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 6)],
                          //show the icon
                          Expanded(
                            child: Text(
                              widget.config.title, //show the title of the window
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    // the building of the widget that gets shown when the menu bar gets dragged (basically the same widget)
                    key: _headerKey,
                    height: 32,
                    decoration: BoxDecoration(color: (widget.config.headerColor ?? const Color(0xFF2D2D30)).withAlpha(127)),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        if (widget.config.icon != null) ...[Icon(widget.config.icon, size: 16, color: Colors.grey.shade600), const SizedBox(width: 6)],
                        Expanded(
                          child: Text(
                            widget.config.title,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                  child: Container(
                    key: _headerKey,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isHoveringHeader
                          ? (widget.config.headerColor ?? const Color(0xFF2D2D30)).withAlpha(204)
                          : (widget.config.headerColor ?? const Color(0xFF2D2D30)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        if (widget.config.icon != null) ...[Icon(widget.config.icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 6)],
                        Expanded(
                          child: Text(
                            widget.config.title,
                            style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: widget.config.child), //show the actual content below in an expanded so that it fits into the space
          ],
        ),
      );
    },
  );
}

