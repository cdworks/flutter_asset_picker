import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:asset_picker/asset_picker.dart';

void main()
{
  runApp(MyApp());
  SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(statusBarColor:Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
//    cleanAssetPickCache();


    return CupertinoApp(
      title: 'Flutter Demo',
      home:HomeWidget(),

    );
  }
}

class HomeWidget extends StatefulWidget
{
  const HomeWidget();
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _HomeWidget();
  }

}

class _HomeWidget extends State<HomeWidget> {

  Image pic;

  @override
  void initState() {
    super.initState();
//    getAllPhoto();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> getAllPhoto() async {
    await showAssetPickNavigationDialog(context: context,
        photoDidSelectCallBack: (assets)
        {
          if(assets != null) {
            print(assets.first.identifier);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return

      CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.white, middle: const Text('home')),
        backgroundColor: Colors.white,
        child: Center(child: CupertinoButton(child: Text('选择'),
            onPressed: () {
              getAllPhoto();
//              Navigator.of(context).push(
//                  CupertinoPageRoute<void>(
//                     builder: (BuildContext context)
//                         {
//                             return AssetNavigationWidget();
//                         }
//                  ),
//              );

            }
        )
        )
    );
  }
}
