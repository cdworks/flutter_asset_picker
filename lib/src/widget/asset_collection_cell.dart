

import 'dart:ui';

import 'package:asset_picker/src/widget/pick_base_cell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cell_event.dart';

class AssetCollectionCell extends CellEvent {

  final String title;
  final int count;
  final Widget icon;

  const AssetCollectionCell({this.title = '', this.icon, this.count = 0,
    GestureTapCallback tapCallback}) :super(tapCallback: tapCallback);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    Widget child = Container(
      height: 66,
      child: Row(
        children: <Widget>[
          SizedBox(width: 66, height: 66, child: icon),
          Padding(padding: EdgeInsets.only(left: 12)),
          Text(title, style: TextStyle(fontSize: 17)),
          Padding(padding: EdgeInsets.only(left: 6)),
          Expanded(child:
          Text('($count)',
            style: TextStyle(color: Color(0xFF808080), fontSize: 16),),
          ),
          Icon(Icons.arrow_forward_ios,color: Color(0xFFCCCCCC),size: 15,)
          ,
          Padding(padding: EdgeInsets.only(left: 15)),
        ],
      ),
    );
    return PickBaseCell(child: child,tapCallback: tapCallback,);
  }
}
