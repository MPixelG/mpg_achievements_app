import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChangeableWidget extends StatefulWidget {
  final Widget Function() builder;
  final double initialX;
  final double initialY;

  const ChangeableWidget({
    super.key,
    required this.builder,
    this.initialX = 0,
    this.initialY = 0,
  });

  @override
  State<ChangeableWidget> createState() => _ChangeableWidgetState();
}

class _ChangeableWidgetState extends State<ChangeableWidget> {
  late double x;
  late double y;
  double width = 150;
  double height = 50;

  @override
  void initState() {
    super.initState();
    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },
        onSecondaryTapDown: (details) => _showContextMenu(context, details.globalPosition),
        child: Stack(
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red),
              ),
              child: widget.builder(),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    width += details.delta.dx;
                    height += details.delta.dy;
                  });
                },
                child: Icon(Icons.open_in_full, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showContextMenu(BuildContext context, Offset position) async {
  final selected = await showMenu<String>(
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
      ),
      PopupMenuItem(
        value: 'edit',
        child: Text('Edit'),
      ),
    ],
  );

  if (selected != null) {
    if (selected == 'delete') {
      print("Deleted");
    } else if (selected == 'edit') {
      print("edited");
    }
  }
}

