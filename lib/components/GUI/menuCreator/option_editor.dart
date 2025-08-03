import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/button_action.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/layout_widget.dart';
import 'package:mpg_achievements_app/components/GUI/menuCreator/widget_options.dart';

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
        SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              Stack(children: [Text(option.name, style: TextStyle(fontSize: 18)), SizedBox(width: 160, height: 32, child: Tooltip(message: option.description ?? "", ))]),
              _buildValueEditor(option),
            ],
          ),
        )
      );
    }


    return propertyWidgets;
  }


  final Map<String, TextEditingController> _textControllers = {};

  TextEditingController _getTextController(String name, Map<String, dynamic> properties, {String controllerName = ""}) {
    final value = properties[name]?.toString() ?? "";

    if (_textControllers.containsKey(controllerName + name)) {
      if (_textControllers[controllerName + name]!.text != value &&
          !_textControllers[controllerName + name]!.selection.isValid) {
        _textControllers[controllerName + name]!.text = value;
      }
    } else {
      _textControllers[controllerName + name] = TextEditingController(text: value);
    }

    return _textControllers[controllerName + name]!;
  }



  Widget _buildValueEditor(WidgetOption option) {

    if(option.options != null){
      return _buildDropdownButton(option);
    } else if(option.type == String) {
      return _buildInputField(option.name, widget.node.properties, TextInputType.text);
    } else if (option.type == int) {
      return _buildInputField(option.name, widget.node.properties, TextInputType.numberWithOptions(decimal: false));
    } else if (option.type == double) {
      return _buildInputField(option.name, widget.node.properties, TextInputType.numberWithOptions(decimal: true));
    } else if (option.type == bool) {
      return _buildSwitch(option);
    } else if (option.type == Color) {
      return _buildColorPicker(option);
    } else if (option.type == ButtonAction){
      return _buildButtonAction(option, widget.node.properties);
    } else if (option.defaultValue is EdgeInsetsGeometry?) {
      return _buildEdgeInsetsEditor(context, option, widget.node.properties);
    }



    return Text(
      'Unsupported type: ${option.type}',
      style: TextStyle(color: Colors.red),
    );

  }


  DropdownButton _buildDropdownButton(WidgetOption option) {
    String currentValue = widget.node.properties[option.name]?.toString() ?? "none";


    String prefix = currentValue.contains(".") ? currentValue.split(".").first : "";

    return DropdownButton<String>(
      value: widget.node.properties[option.name]?.toString(),
      alignment: Alignment.centerRight,
      underline: Container(color: CupertinoColors.systemBackground,),

      items: [for (MapEntry<String, dynamic> entry in option.options!.entries)

        DropdownMenuItem<String>(
            value: entry.value.toString(),
            alignment: Alignment.center, child: Text(entry.key)
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

  Row _buildColorPicker(WidgetOption option) {
    Color currentColor = parseColor(widget.node.properties[option.name]) ?? Colors.black;
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
  }

  Switch _buildSwitch(WidgetOption option) {
    return Switch(
      value: widget.node.properties[option.name] ?? false,
      onChanged: (bool newValue) {
        setState(() {
          widget.node.properties[option.name] = newValue;
          widget.updateView();
        });
      },
    );
  }


  Widget _buildEdgeInsetsEditor(BuildContext context, WidgetOption option, Map<String, dynamic> properties) {
    return FloatingActionButton(onPressed: (){
      _showEdgeInsetsDialog(context, option, properties);
    },
      child: Icon(Icons.edit_note_outlined),
    );
  }


  void _showEdgeInsetsDialog(BuildContext context, WidgetOption option, Map<String, dynamic> properties) {

    properties[option.name] ??= <String, double>{};

    properties[option.name]["left"] ??= 0.0;
    properties[option.name]["top"] ??= 0.0;
    properties[option.name]["right"] ??= 0.0;
    properties[option.name]["bottom"] ??= 0.0;


    showDialog(context: context, builder: (context) => Dialog(

      backgroundColor: Colors.white,
      child: SizedBox(
        width: 480,
          height: 300,
          child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("EdgeInsets Editor for ${option.name}"),
          backgroundColor: CupertinoColors.systemGrey4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(24)),
        ),
        body: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputField("left", properties[option.name], TextInputType.numberWithOptions(decimal: true), controllerName: option.name),
                  _buildInputField("top", properties[option.name], TextInputType.numberWithOptions(decimal: true), controllerName: option.name),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputField("right", properties[option.name], TextInputType.numberWithOptions(decimal: true), controllerName: option.name),
                  _buildInputField("bottom", properties[option.name], TextInputType.numberWithOptions(decimal: true), controllerName: option.name),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    properties[option.name] = {
                      "left": double.tryParse(
                          properties[option.name]["left"]?.toString() ?? "0") ?? 0.0,
                      "top": double.tryParse(
                          properties[option.name]["top"]?.toString() ?? "0") ?? 0.0,
                      "right": double.tryParse(
                          properties[option.name]["right"]?.toString() ?? "0") ?? 0.0,
                      "bottom": double.tryParse(
                          properties[option.name]["bottom"]?.toString() ?? "0") ?? 0.0,
                    };
                    widget.updateView();
                  });
                  Navigator.of(context).pop();
                },
                child: Text("Apply"),
              ),
            ],
          ),
        ),
      )
      )
      )
    );
  }





  SizedBox _buildInputField(String name, Map<String, dynamic> properties, TextInputType? textInputType, {String? controllerName, void Function(dynamic)? onChange}) {
    TextEditingController controller = _getTextController(name, controllerName: controllerName ?? "", properties); //if a controllerName is provided, use it as a prefix for the controller name. if not, use the name directly

    return SizedBox(
      width: 130,
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: textInputType,
        onChanged: (dynamic newValue) {
          if(onChange != null) onChange(newValue);
          setState(() {
            dynamic parsedValue = newValue;
            Type expectedType = properties[name]?.runtimeType ?? String;

            if (expectedType == int) {
              parsedValue = int.tryParse(newValue) ?? 0;
            } else if (expectedType == double) {
              parsedValue = double.tryParse(newValue) ?? 0.0;
            }

            properties[name] = parsedValue;
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





  Widget _buildButtonAction(WidgetOption option, Map<String, dynamic> propertiesFull) {

    propertiesFull["onPressed"] ??= <String, dynamic>{};

    Map<String, dynamic> pressProperties = propertiesFull["onPressed"];

    return SizedBox(
      width: 120,
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    Map<String, dynamic> pressProperties = propertiesFull["onPressed"];

                    return SizedBox(
                      width: 600,
                      height: 400,
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          title: Text("Button Action Editor"),
                          backgroundColor: CupertinoColors.systemGrey4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        body: Padding(
                          padding: const EdgeInsets.all(24),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Type"),
                                    _buildInputField("actionType", pressProperties, TextInputType.text, onChange: (newVal) {
                                      propertiesFull["onPressed"]["actionType"] = newVal;

                                      setDialogState(() {
                                        propertiesFull["onPressed"] = {...ButtonAction.fromJson(propertiesFull["onPressed"]).toJson()};
                                      });

                                      setState(() {});
                                      widget.updateView();
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...pressProperties.entries
                                    .where((entry) => entry.key != "actionType")
                                    .map((entry) => _buildButtonEntry(entry, pressProperties))
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },

        child: Text(option.name),
      ),
    );
  }

  Row _buildButtonEntry(MapEntry<String, dynamic> entry, Map<String, dynamic> properties){

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(entry.key),

        _buildInputField(entry.key, properties, TextInputType.text)


      ],
    );

  }

  @override
  void dispose() {
    _textControllers.entries.forEach((element) => element.value.dispose());

    super.dispose();
  }





}