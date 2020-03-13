

import 'package:flutter/cupertino.dart';

abstract class CellEvent extends StatelessWidget
{
  final Color selectedColor;
  final Color highlightColor;
  final Color normalColor;
  final bool  selected;

  final GestureTapCallback tapCallback;
  final GestureLongPressCallback longPressCallback;

  const CellEvent({this.tapCallback,this.longPressCallback,this.selectedColor, this.highlightColor, this.normalColor, this.selected,});
}
