import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../options/widget_options.dart';
import '../dependencyViewer/layout_widget.dart';
import 'button_action.dart';

class OptionEditorMenu extends StatefulWidget {

  OptionEditorMenu({
    super.key,
    required LayoutWidget node,
    required this.updateView
  }){
    _currentWidget = [node];
  }

  final VoidCallback updateView;


  late final List<LayoutWidget> _currentWidget;

  LayoutWidget get node => _currentWidget.first;
  set node(LayoutWidget newNode) {
    _currentWidget[0] = newNode;
    updateView();
  }



  @override
  State<StatefulWidget> createState() => OptionEditorMenuState();
}

class OptionEditorMenuState extends State<OptionEditorMenu> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.node.widgetType} Properties",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 48),
              ..._buildPropertyWidgets(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPropertyWidgets() {
    WidgetOptions widgetOptions = WidgetOptions.fromType(
      widget.node.widgetType,
    );

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
              Stack(
                children: [
                  Text(option.name, style: TextStyle(fontSize: 18)),
                  SizedBox(
                    width: 160,
                    height: 32,
                    child: Tooltip(message: option.description ?? ""),
                  ),
                ],
              ),
              _buildValueEditor(option),
            ],
          ),
        ),
      );
    }

    return propertyWidgets;
  }

  final Map<String, TextEditingController> _textControllers = {};

  TextEditingController _getTextController(
    String name,
    String widgetId,
    Map<String, dynamic> properties, {
    String controllerName = "",
  }) {
    final value = properties[name]?.toString() ?? "";

    if (_textControllers.containsKey(controllerName + name + widgetId)) {
      if (_textControllers[controllerName + name + widgetId]!.text != value &&
          !_textControllers[controllerName + name + widgetId]!.selection.isValid) {
        _textControllers[controllerName + name + widgetId]!.text = value;
      }
    } else {
      _textControllers[controllerName + name + widgetId] = TextEditingController(
        text: value,
      );
    }

    return _textControllers[controllerName + name + widgetId]!;
  }

  Widget _buildValueEditor(WidgetOption option) {
    if (option.options != null) {
      return _buildDropdownButton(option);
    } else if (option.type == String) {
      return _buildInputField(
        option.name,
        widget.node.properties,
        TextInputType.text,
      );
    } else if (option.type == int) {
      return _buildInputField(
        option.name,
        widget.node.properties,
        TextInputType.numberWithOptions(decimal: false),
      );
    } else if (option.type == double) {
      return _buildInputField(
        option.name,
        widget.node.properties,
        TextInputType.numberWithOptions(decimal: true),
      );
    } else if (option.type == bool) {
      return _buildSwitch(option);
    } else if (option.type == Color) {
      return _buildColorPicker(option);
    } else if (option.type == ButtonAction) {
      return _buildButtonAction(option, widget.node.properties);
    } else if (option.defaultValue is EdgeInsetsGeometry?) {
      return _buildEdgeInsetsEditor(context, option, widget.node.properties);
    } else if (option.type == TextStyle) {
      return _buildTextStyleEditor(option, widget.node.properties);
    }

    return Text(
      'Unsupported type: ${option.type}',
      style: TextStyle(color: Colors.red),
    );
  }

  DropdownButton _buildDropdownButton(WidgetOption option) {
    String currentValue =
        widget.node.properties[option.name]?.toString() ?? "none";

    String prefix = currentValue.contains(".") ? currentValue.split(".").first : "";

    return DropdownButton<String>(
      value: widget.node.properties[option.name]?.toString(),
      alignment: Alignment.centerRight,
      underline: Container(color: CupertinoColors.systemBackground),

      items: [
        for (MapEntry<String, dynamic> entry in option.options!.entries)
          DropdownMenuItem<String>(
            value: entry.value.toString(),
            alignment: Alignment.center,
            child: Text(entry.key),
          ),
      ],

      onChanged: (String? newValue) {
        setState(() {
          widget.node.properties[option.name] = newValue;
          widget.updateView();
        });
      },
      hint: Text(currentValue.replaceAll("$prefix.", "")),
    );
  }

  Row _buildColorPicker(
    WidgetOption option, {
    Map<String, dynamic>? properties,
    String? customOptionName,
    StateSetter? stateSetter,
  }) {
    properties ??= widget.node.properties;

    Color currentColor = parseColor(properties[customOptionName ?? option.name]) ?? Colors.black;
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
                        properties![customOptionName ?? option.name] =
                            pickedColor;

                        if (stateSetter != null) {
                          stateSetter(() {});
                        }

                        setState(() {
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

  Widget _buildEdgeInsetsEditor(
    BuildContext context,
    WidgetOption option,
    Map<String, dynamic> properties,
  ) {
    return FloatingActionButton(
      heroTag: null,
      onPressed: () {
        _showEdgeInsetsDialog(context, option, properties);
      },
      child: Icon(Icons.edit_note_outlined),
    );
  }

  void _showEdgeInsetsDialog(
    BuildContext context,
    WidgetOption option,
    Map<String, dynamic> properties,
  ) {
    properties[option.name] ??= <String, double>{};

    properties[option.name]["left"] ??= 0.0;
    properties[option.name]["top"] ??= 0.0;
    properties[option.name]["right"] ??= 0.0;
    properties[option.name]["bottom"] ??= 0.0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: SizedBox(
          width: 480,
          height: 300,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text("EdgeInsets Editor for ${option.name}"),
              backgroundColor: CupertinoColors.systemGrey4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(24),
              ),
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
                      _buildInputField(
                        "left",
                        properties[option.name],
                        TextInputType.numberWithOptions(decimal: true),
                        controllerName: option.name,
                      ),
                      _buildInputField(
                        "top",
                        properties[option.name],
                        TextInputType.numberWithOptions(decimal: true),
                        controllerName: option.name,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputField(
                        "right",
                        properties[option.name],
                        TextInputType.numberWithOptions(decimal: true),
                        controllerName: option.name,
                      ),
                      _buildInputField(
                        "bottom",
                        properties[option.name],
                        TextInputType.numberWithOptions(decimal: true),
                        controllerName: option.name,
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        properties[option.name] = {
                          "left":
                              double.tryParse(
                                properties[option.name]["left"]?.toString() ??
                                    "0",
                              ) ??
                              0.0,
                          "top":
                              double.tryParse(
                                properties[option.name]["top"]?.toString() ??
                                    "0",
                              ) ??
                              0.0,
                          "right":
                              double.tryParse(
                                properties[option.name]["right"]?.toString() ??
                                    "0",
                              ) ??
                              0.0,
                          "bottom":
                              double.tryParse(
                                properties[option.name]["bottom"]?.toString() ??
                                    "0",
                              ) ??
                              0.0,
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
          ),
        ),
      ),
    );
  }

  SizedBox _buildInputField(
    String name,
    Map<String, dynamic> properties,
    TextInputType? textInputType, {
    String? controllerName,
    void Function(dynamic)? onChange,
  }) {
    TextEditingController controller = _getTextController(
      name,
      widget.node.id,
      controllerName: controllerName ?? "",
      properties,
    ); //if a controllerName is provided, use it as a prefix for the controller name. if not, use the name directly

    return SizedBox(
      width: 130,
      height: 60,
      child: TextField(
        controller: controller,
        keyboardType: textInputType,
        onChanged: (dynamic newValue) {
          if (onChange != null) onChange(newValue);
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

  Widget _buildButtonAction(
    WidgetOption option,
    Map<String, dynamic> propertiesFull,
  ) {
    propertiesFull["onPressed"] ??= <String, dynamic>{};

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
                    Map<String, dynamic> pressProperties =
                        propertiesFull["onPressed"];

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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Type"),
                                    _buildInputField(
                                      "actionType",
                                      pressProperties,
                                      TextInputType.text,
                                      onChange: (newVal) {
                                        propertiesFull["onPressed"]["actionType"] =
                                            newVal;

                                        setDialogState(() {
                                          propertiesFull["onPressed"] = {
                                            ...ButtonAction.fromJson(
                                              propertiesFull["onPressed"],
                                            ).toJson(),
                                          };
                                        });

                                        setState(() {});
                                        widget.updateView();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...pressProperties.entries
                                    .where((entry) => entry.key != "actionType")
                                    .map(
                                      (entry) => _buildButtonEntry(
                                        entry,
                                        pressProperties,
                                        setDialogState,
                                      ),
                                    )
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

  Row _buildButtonEntry(
    MapEntry<String, dynamic> entry,
    Map<String, dynamic> properties,
    StateSetter setDialogState, {
    WidgetOption? option,
    String? customOptionName,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(entry.key),
        switch (entry.value.runtimeType) {
          Color => _buildColorPicker(
            option!,
            properties: properties,
            customOptionName: customOptionName,
            stateSetter: setDialogState,
          ),
          Type() => _buildInputField(entry.key, properties, TextInputType.text),
        },
      ],
    );
  }

  Widget _buildTextStyleEditor(
    WidgetOption option,
    Map<String, dynamic> properties,
  ) {
    Map<String, dynamic> newStyle = {
      ...?properties["style"],
      "color": Colors.black,
      "fontFamily": "gameFont",
      "backgroundColor": Colors.transparent,
      "wordSpacing": null,
      "letterSpacing": null,
    };

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
                  // setDialogState wird hier vom Builder bereitgestellt
                  builder: (context, setDialogState) {
                    return SizedBox(
                      width: 600,
                      height: 400,
                      child: Scaffold(
                        // ... (dein AppBar Code)
                        appBar: AppBar(
                          title: Text("TextStyle Editor"),
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
                                const SizedBox(height: 16),
                                ...newStyle.entries
                                    // Reiche setDialogState hier an _buildButtonEntry weiter
                                    .map(
                                      (entry) => _buildButtonEntry(
                                        entry,
                                        properties["style"],
                                        setDialogState,
                                        option: option,
                                        customOptionName: entry.key,
                                      ),
                                    )
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

  @override
  void dispose() {
    _textControllers.entries.forEach((element) => element.value.dispose());

    super.dispose();
  }
}
