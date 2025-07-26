import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/nine_patch_button.dart';
import 'ChangableWidget.dart';

class MenuCreator extends StatefulWidget {
  const MenuCreator({super.key});

  @override
  _MenuCreatorState createState() => _MenuCreatorState();
}

class _MenuCreatorState extends State<MenuCreator> {

  List<Widget> children = [];

  void addNewWidget() {
    setState(() {
      children.add(
        ChangeableWidget(
          initialX: 100,
          initialY: 100,
          builder: () => NinePatchButton(
            text: "test",
            onPressed: () {},
            imageName: "button_0",
            borderX: 3,
            borderY: 3,
            borderX2: 3,
            borderY2: 3,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack( // Muss Stack sein!
        children: [
          ...children,
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewWidget,
        child: Icon(Icons.add),
      ),
    );
  }
}