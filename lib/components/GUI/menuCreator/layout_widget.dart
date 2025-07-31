import 'package:flutter/cupertino.dart';
class LayoutWidget {
  final String id;
  final Widget Function(BuildContext context, List<Widget> children, Map<String, dynamic> properties) _builder;
  late final List<LayoutWidget> children;
  Map<String, dynamic> properties;

  LayoutWidget(this._builder, {
    required this.id,
    List<LayoutWidget>? children,
    this.properties = const {},
  }){
    this.children = children ?? [];
  }

  void addChild(LayoutWidget child) {
    children.add(child);
  }

  void removeChild(LayoutWidget child) {
    children.remove(child);
  }

  Widget build(BuildContext context) {
    return _builder(context, children.map((c) => c.build(context)).toList(), properties);
  }
}
