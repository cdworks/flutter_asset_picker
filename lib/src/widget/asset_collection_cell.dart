

import 'dart:ui';

import 'package:asset_picker/src/widget/pick_base_cell.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'cell_event.dart';

class AssetCollectionCell extends StatelessWidget {

  final String title;
  final int count;
  final Widget icon;
  final GestureTapCallback callback;

  const AssetCollectionCell({this.title = '', this.icon, this.count = 0,
    this.callback}) ;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    Widget child = Container(
      height: 66,
      child: Row(
        children: <Widget>[
          SizedBox(width: 66, height: 66, child: icon),
          Padding(padding: EdgeInsets.only(left: 12)),
          Text(title, style: TextStyle(fontSize: 17,color: CupertinoDynamicColor.withBrightness(color: CupertinoColors.black, darkColor: Color(0xFF333333 ^ 0x00FFFFFF)) .resolveFrom(context))),
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
    return PickBaseCell(child: child,tapCallback: callback,);
  }
}
