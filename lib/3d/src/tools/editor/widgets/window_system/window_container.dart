import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/3d/src/tools/editor/widgets/window_system/window_type_registry.dart';


class WindowPane extends StatefulWidget {
  final WindowConfig config;
  final WindowNode node;
  final Function(WindowConfig)? onSwap;
  final Function(Axis)? onSplit;

  const WindowPane({super.key, required this.config, required this.node, this.onSwap, this.onSplit});

  @override
  State<WindowPane> createState() => _WindowPaneState();
}

class _WindowPaneState extends State<WindowPane> {
  bool _isHoveringHeader = false;
  final GlobalKey _headerKey = GlobalKey();

  void _showWindowMenu(BuildContext context, Offset tapPosition) {
    final RenderBox? renderBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(tapPosition.dx, position.dy + renderBox.size.height, tapPosition.dx, position.dy + renderBox.size.height),
      items: [
        const PopupMenuItem(
          value: "change_type",
          child: Row(children: [Icon(Icons.swap_horiz, size: 18), SizedBox(width: 8), Text("Change window type")]),
        ),
        const PopupMenuItem(
          value: "split_horizontally",
          child: Row(children: [Icon(Icons.horizontal_split, size: 18), SizedBox(width: 8), Text("Split horizontally")]),
        ),
        const PopupMenuItem(
          value: "split_vertically",
          child: Row(children: [Icon(Icons.vertical_split, size: 18), SizedBox(width: 8), Text("Split vertically")]),
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

  void _showTypeSelector(BuildContext context) {
    final types = WindowTypeRegistry.getAll();
    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Window types registered!"), duration: Duration(seconds: 2)));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose your widow type"),
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
  Widget build(BuildContext context) => DragTarget<WindowConfig>(
    onWillAcceptWithDetails: (details) => true,
    onAcceptWithDetails: (details) {
      if (widget.onSwap != null) {
        widget.onSwap!(details.data);
      }
    },
    builder: (context, candidateData, rejectedData) {
      final isHovering = candidateData.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: isHovering ? Colors.blue : Colors.grey.shade800, width: isHovering ? 2 : 1),
          color: const Color(0xFF1E1E1E),
        ),
        child: Column(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveringHeader = true),
              onExit: (_) => setState(() => _isHoveringHeader = false),
              child: GestureDetector(
                onTapDown: (details) => _showWindowMenu(context, details.globalPosition),
                child: Draggable<WindowConfig>(
                  data: widget.config,
                  feedback: Material(
                    elevation: 8,
                    child: Container(
                      width: 200,
                      height: 32,
                      decoration: BoxDecoration(color: widget.config.headerColor ?? const Color(0xFF2D2D30), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          if (widget.config.icon != null) ...[Icon(widget.config.icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 6)],
                          Expanded(
                            child: Text(
                              widget.config.title,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
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
            Expanded(child: widget.config.child),
          ],
        ),
      );
    },
  );
}

abstract class WindowNode {}

class WindowLeaf extends WindowNode {
  final WindowConfig config;

  WindowLeaf({required this.config});
}

class WindowSplit extends WindowNode {
  final Axis direction;
  final List<WindowNode> children;

  WindowSplit({required this.direction, required this.children});
}
