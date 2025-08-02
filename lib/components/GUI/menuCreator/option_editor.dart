import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/button_action.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_options.dart';
import 'package:mpg_achievements_app/components/GUI/widgets/nine_patch_button.dart';

class OptionEditorMenu extends StatefulWidget {
  const OptionEditorMenu({super.key, required this.node, required this.updateView});

  final VoidCallback updateView;

  final LayoutWidget node;

  @override
  State<StatefulWidget> createState() => _OptionEditorMenuState();



}

class _OptionEditorMenuState extends State<OptionEditorMenu> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(50),
      backgroundColor: Colors.white,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text("Properties Editor for ${widget.node.widgetType}"), //the title of the app bar is the id of the node
          ),

          body: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.extraLightBackgroundGray,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Node Properties",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 48),
                  ..._buildPropertyWidgets()
                ],
              ),
            ),
          ),
        ),
    );
  }

  List<Widget> _buildPropertyWidgets() {
    WidgetOptions widgetOptions = WidgetOptions.fromType(widget.node.widgetType);


    List<Widget> propertyWidgets = [];

    for (var option in widgetOptions.options) {
      propertyWidgets.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            Text(option.name, style: TextStyle(fontSize: 18)),
            _buildValueEditor(option),
          ],
        ),
      );
    }


    return propertyWidgets;
  }


  final Map<String, TextEditingController> _textControllers = {};

  TextEditingController _getTextController(String name) {
    if (!_textControllers.containsKey(name)) {
      _textControllers[name] = TextEditingController(text: widget.node.properties[name]?.toString());
    }
    return _textControllers[name]!;
  }


  Widget _buildValueEditor(WidgetOption option) {

    if(option.options != null){

      String currentValue = widget.node.properties[option.name]?.toString() ?? "";


      String prefix = currentValue.contains(".") ? currentValue.split(".").first : "";

      return DropdownButton<String>(
        value: widget.node.properties[option.name]?.toString(),
        alignment: Alignment.centerRight,
        underline: Container(color: CupertinoColors.systemBackground,),

        items: [for (dynamic value in option.options!)

          DropdownMenuItem<String>(
            value: value.toString(),
            alignment: Alignment.center, child: Text(value.toString().replaceAll("$prefix.", ""))
          )],

        onChanged: (String? newValue) {
          setState(() {
            widget.node.properties[option.name] = newValue;
            widget.updateView();
          });
        },
        hint: Text(currentValue.replaceAll("$prefix.", "")),
      );

    }

    if(option.type == String) {
      return _buildInputField(option.name, widget.node.properties[option.name], TextInputType.text);
    } else if (option.type == int) {
      return _buildInputField(option.name, widget.node.properties[option.name], TextInputType.numberWithOptions(decimal: false));
    } else if (option.type == double) {
    return _buildInputField(option.name, widget.node.properties[option.name], TextInputType.numberWithOptions(decimal: true));
    } else if (option.type == bool) {
      return Switch(
        value: widget.node.properties[option.name] ?? false,
        onChanged: (bool newValue) {
          setState(() {
            widget.node.properties[option.name] = newValue;
            widget.updateView();
          });
        },
      );
    } else if (option.type == Color) {
      Color currentColor = widget.node.properties[option.name] ?? Colors.black;
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              Color pickedColor = currentColor;
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: currentColor,
                        onColorChanged: (Color color) {
                          pickedColor = color;
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          setState(() {
                            widget.node.properties[option.name] = pickedColor;
                            widget.updateView();
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentColor,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      );
    } else if (option.type == ButtonAction){
      print("ButtonAction detected: ${option.name}");
      return _buildButtonAction(option, widget.node.properties[option.name]);
    }

    return Text(
      'Unsupported type: ${option.type}',
      style: TextStyle(color: Colors.red),
    );

  }


  SizedBox _buildInputField(String name, dynamic value, TextInputType? textInputType) {
    TextEditingController controller = _getTextController(name);

    return SizedBox(
      width: 130,
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: textInputType,
        onChanged: (String newValue) {
          setState(() {
            widget.node.properties[name] = newValue;
            widget.updateView();
          });
        },
        decoration: InputDecoration(
          labelText: name,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }


  Widget _buildButtonAction(WidgetOption option, dynamic value) {
    return SizedBox(
      width: 120,
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          showDialog(context: context,
              builder: (context) {
                return SizedBox(
                  width: 600,
                  height: 400,
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      title: Text("Button Action Editor"),
                      backgroundColor: CupertinoColors.systemGrey4,
                    ),

                    body: Container(color: Colors.white,
                      child: SingleChildScrollView(

                        child: Column(





                        ),



                      ),

                    ),



                  )
                );
              });

        },
        child: Text(option.name),
      ),
    );
  }

  @override
  void dispose() {

    _textControllers.entries.forEach((element) => element.value.dispose());

    super.dispose();
  }





}