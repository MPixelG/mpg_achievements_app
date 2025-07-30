import 'package:flutter/cupertino.dart';

class LayoutWidget<T extends Widget> {
  final List<Widget> _children = [];
  final Widget Function(List<Widget>) _builder;

  LayoutWidget(this._builder);

  void addChild(Widget child) {
    _children.add(child);
  }

  Widget build() => _builder(_children);
}
