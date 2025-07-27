import 'package:flutter/material.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/editable_widget.dart';

class GuiEditor extends StatefulWidget { //the GUI editor lets us create guis and later export them as a json TODO
  const GuiEditor({super.key});

  @override
  State<StatefulWidget> createState() => _GuiEditorState(); //the state of the widget. we have a separate class for that.
}

class _GuiEditorState extends State<GuiEditor> { //the state class for the GUI editor.
  late EditorNode rootNode; //the root node. it also contains all of the other nodes as children

  @override
  void initState() { //init the variables
    super.initState();

    rootNode = EditorNode( //init the root node. for now its just a placeholder colored container TODO
            () => Container( //a colored container
          width: 120, //with a width of 120
          height: 80, //height of 80
          color: Colors.blue.withValues(alpha: .3) //and a translucent blue as a color
        ),
        GlobalKey(), //we use a global key as a key bc its easy and unique
        properties: {'position': Offset(0.4, 0.3)} //set a position for the node in its properties
    );
  }

  @override
  Widget build(BuildContext context) { //here we actually build the stuff thats being rendered
    return Scaffold( //we use a scaffold bc it lets us easily add components with some presets.
      backgroundColor: Colors.transparent, //set the background color to transparent so that we can see the stuff behind the menu
        body: EditableWidget( // add the actual widget
          key: GlobalKey(), //with a global key
          rootNode, //the root node we defined
          isRoot: true, //and set root node to true
        ),
    );
  }
}