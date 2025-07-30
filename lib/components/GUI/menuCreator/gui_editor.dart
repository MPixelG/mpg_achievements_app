import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
class GuiEditor extends StatefulWidget { //the GUI editor lets us create guis and later export them as a json TODO
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> { //the state class for the GUI editor.

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.width;

  LayoutWidget? root;

  @override
  void initState() {

    root = addContainer();

    super.initState();
  }


  @override
  Widget build(BuildContext context) { //here we actually build the stuff thats being rendered
    return Scaffold( //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors.white,
        body: root!.build(context),

      floatingActionButton: FloatingActionButton(onPressed: addWidget),
    );
  }

  void addWidget(){
    setState(() {
      root!.addChild(addContainer().build(context));
    });
  }


  LayoutWidget addContainer(){
    LayoutWidget widget = LayoutWidget((context, children, properties) {

      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;

      return Container(
        color: Colors.primaries.random(),
        width: (properties["width"] ?? 0.3) * screenWidth,
        height: (properties["height"] ?? 0.3) * screenHeight,
        child: Stack(children: children),
      );
    });

    return widget;
  }
}