import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';


import 'package:asset_picker/asset_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toast/toast.dart';

import 'asset_collection_cell.dart';
import 'asset_cupertino_page_route.dart';
import 'asset_image.dart';

typedef AssetPickedCallback = void Function(List<Asset>);

Future cleanAssetPickCache() async {
  Directory dir = await getApplicationDocumentsDirectory();
  Directory cachePath = Directory("${dir.path}/pickasset/imagecache/");
  if (cachePath.existsSync()) {
    await File(cachePath.path).delete(recursive: true);
  }
}

Future<double> _getTotalSizeOfFilesInDir(final FileSystemEntity file) async {
  if (file is File) {
    int length = await file.length();
    return double.parse(length.toString());
  }
  if (file is Directory) {
    try {
      final List<FileSystemEntity> children = file.listSync();
      double total = 0;
      if (children != null)
        for (final FileSystemEntity child in children)
          total += await _getTotalSizeOfFilesInDir(child);
      return total;
    } catch (e) {}
  }
  return 0;
}

Future<double> getAssetPickCacheSize() async
{
  double size = 0;
  Directory dir = await getApplicationDocumentsDirectory();
  Directory cachePath = Directory("${dir.path}/pickasset/imagecache/");
  if (cachePath.existsSync()) {
    size = await _getTotalSizeOfFilesInDir(cachePath);
  }
  return size;
}

Future showAssetPickNavigationDialog<T>(
    {@required BuildContext context,
    int maxNumber = 8,
    int type = 0,
      Color textColor = Colors.black,
    AssetPickedCallback photoDidSelectCallBack
//  @required WidgetBuilder builder,
    }) {
//  assert(builder != null);
  final navigator = Navigator.of(context);


  var pageScaffold = AssetNavigationPageScaffold(
    myContent: context,
    maxNumber: maxNumber,
    barTitleColor: textColor,
    type: type,
    photoDidSelectCallBack: photoDidSelectCallBack,
  );

  PageRoute pageRoute = CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) {
        return pageScaffold;
      });
   pageScaffold.route = pageRoute;
  navigator.push(pageRoute);

  return navigator.push(
      AssetCupertinoPageRoute(
        builder: (context1)
        {
          return PhotoPickerPageScaffold(
            myContent: context,
            assetCollection: AssetCollection('all_identifier', '所有照片', 0),
            parentRoute: pageRoute,
            barTitleColor: textColor,
            maxNumber: maxNumber,
            type: type,
            photoDidSelectCallBack: photoDidSelectCallBack,
          );
        },
        beginSlider: false,
        route: pageRoute,
      )
      );
}

// ignore: must_be_immutable
class AssetNavigationPageScaffold extends CupertinoPageScaffold {
  final BuildContext myContent;
  final AssetPickedCallback photoDidSelectCallBack;
  final Color barTitleColor;
  Route route;
  final int maxNumber;

  final int type; //0 图片 1 视频 2 音频 -1 所有的

  ObstructingPreferredSizeWidget get navigationBar => CupertinoNavigationBar(
        middle:  Text('照片',style:TextStyle(color:barTitleColor)),
        automaticallyImplyLeading: false,
        trailing: CupertinoButton(
          child: Text('取消'),
          padding: EdgeInsets.zero,
          minSize: 30,
          onPressed: () {
            Navigator.of(myContent).pop();
          },
        ),
      );

    AssetNavigationPageScaffold(
      {@required this.myContent,
      this.type = 0,
      this.maxNumber = 9,
        this.barTitleColor,
      this.photoDidSelectCallBack})
      : assert(myContent != null),
        super(child: const Text(('')));

  @override
  // TODO: implement child
  Widget get child => NavigationMainPage(
        type: type,
        parentRoute: route,
        photoDidSelectCallBack: photoDidSelectCallBack,
        barTitleColor: barTitleColor,
        maxNumber: maxNumber,
      );
}

class NavigationMainPage extends StatefulWidget {
  final Route parentRoute;
  final AssetPickedCallback photoDidSelectCallBack;
  final Color barTitleColor;
  final int maxNumber;

  final int type; //0 图片 1 视频 2 音频 -1 所有的
  const NavigationMainPage(
      {this.parentRoute, this.maxNumber, this.type, this
          .photoDidSelectCallBack,this.barTitleColor});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _NavigationMainPage();
  }
}

class _NavigationMainPage extends State<NavigationMainPage> {
  List<AssetCollection> _collectionList = [];

  void requestAssetCollection() async {
    try {
      var list = await AssetPicker.getAllAssetCatalog();
      setState(() {
        _collectionList = list;
      });
    } on PlatformException catch (e) {
      Toast.show(e.message, context,gravity: Toast.CENTER,backgroundRadius: 8);
    }
    catch (e)
    {
      Toast.show(e.message, context,gravity: Toast.CENTER);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestAssetCollection();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        var collection = _collectionList[index];

        var query = MediaQuery.of(context);

        final double dWidth = query.size.width * query.devicePixelRatio;
        final int picSizeWidth = collection.lastAsset != null
            ? dWidth ~/ 3.6
            : (query.devicePixelRatio * 66).toInt();

        final int picSizeHeight = collection.lastAsset != null
            ? (picSizeWidth * collection.lastAsset.ration).toInt()
            : picSizeWidth;

//      var thumbSize = (query.devicePixelRatio * 66).toInt();q

        final Widget iconWidget = collection.lastAsset != null
            ? AssetThumbImage(
                width: picSizeWidth,
                height: picSizeHeight,
                asset: collection.lastAsset,
              )
            : Icon(
                Icons.insert_photo,
                size: 66,
                color: Colors.black12,
              );

//        print('last:${collection.lastAsset}');
        return AssetCollectionCell(
          title: collection.name,
          icon: iconWidget,
          count: collection.count,
          tapCallback: () {
            Navigator.of(context).push(
                AssetCupertinoPageRoute(
                  builder: (context1)
                  {
                    return PhotoPickerPageScaffold(
                      myContent: context,
                      assetCollection: collection,
                      parentRoute: widget.parentRoute,
                      maxNumber: widget.maxNumber,
                      barTitleColor: widget.barTitleColor,
                      type: widget.type,
                      photoDidSelectCallBack: widget.photoDidSelectCallBack,
                    );
                  }
                  ,
                  route: widget.parentRoute,
                )
//                CupertinoPageRoute(builder: (context) {
//              return
//              PhotoPickerPageScaffold(
//                myContent: context,
//                assetCollection: collection,
//                parentRoute: widget.parentRoute,
//                maxNumber: widget.maxNumber,
//                type: widget.type,
//                photoDidSelectCallBack: widget.photoDidSelectCallBack,
//              );
//            })
            );
          },
        );
      },
      itemCount: _collectionList.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          color: Color(0xFFE5E5E5),
          height: 0.5,
          thickness: 0.5,
        );
      },
    );
  }
}
