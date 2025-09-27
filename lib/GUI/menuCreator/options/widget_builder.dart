import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

EdgeInsetsGeometry? convertToAbsolute(
  EdgeInsetsGeometry? current,
  double screenWidth,
  double screenHeight,
) {
  if (current == null) return current;

  EdgeInsets resolved = current.resolve(TextDirection.ltr);
  return EdgeInsets.fromLTRB(
    resolved.left * screenWidth,
    resolved.top * screenHeight,
    resolved.right * screenWidth,
    resolved.bottom * screenHeight,
  );
}

TextStyle? convertToAbsoluteTextSize(
  TextStyle? current,
  double screenWidth,
  double screenHeight,
) {
  if (current == null) return null;
  return TextStyle(
    color: current.color,
    fontFamily: current.fontFamily,
    height: current.height,
    background: current.background,
    backgroundColor: current.backgroundColor,
    decoration: current.decoration,
    fontSize: current.fontSize != null
        ? (current.fontSize! * ((screenWidth + screenHeight) / 2))
        : null,
    foreground: current.foreground,
    wordSpacing: current.wordSpacing,
    letterSpacing: current.letterSpacing,
  );
}

int containerIndex = 0; //this is used to give the container widgets a unique id
int rowIndex = 0; //this is used to give the row widgets a unique id
int columnIndex = 0; //this is used to give the row widgets a unique id
int stackId = 0;
int positionedId = 0;
int expandedId = 0;
int textId = 0;
int imageId = 0;
int ninepatchButtonIndex = 0;
int interactiveViewerId = 0;
int singleChildScrollViewId = 0;
int fittedBoxId = 0;
int transformId = 0;
int opacityId = 0;
int cardId = 0;
int gridViewId = 0;
