
import 'dart:ui';

import 'package:asset_picker/asset_picker.dart';
import 'package:asset_picker/src/widget/asset_cupertino_page_route.dart';
import 'package:asset_picker/src/widget/asset_image.dart';
import 'package:asset_picker/src/widget/circle_check_box.dart';
import 'package:asset_picker/src/widget/picker_photo_browser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'circle_check_box.dart';
import 'package:toast/toast.dart';

typedef PopCallback = void Function();

// ignore: must_be_immutable
class PhotoPickerPageScaffold extends CupertinoPageScaffold with AssetRouteWidget
{
  final AssetCollection assetCollection;
  final BuildContext myContent;
//  final Route rootRoute;
  final Route parentRoute;
//  final BuildContext context;
  final AssetPickedCallback photoDidSelectCallBack;
  final Color barTitleColor;
  final int maxNumber;

  final int type; //0 图片 1 视频 2 音频 -1 所有的

  
  
  ObstructingPreferredSizeWidget get navigationBar => CupertinoNavigationBar(
    middle: Text(this.assetCollection.name,style: TextStyle(color: barTitleColor),),
    trailing: CupertinoButton(child: Text('取消'), padding: EdgeInsets.zero,minSize: 30,onPressed: ()
     {
       popToDismiss();
    },),

  );
   PhotoPickerPageScaffold({@required this.myContent,@required this
       .assetCollection,this.photoDidSelectCallBack,this.type,
    this.maxNumber,this.parentRoute,this.barTitleColor})
      :assert(myContent != null),assert(assetCollection != null),
        super(child: const Text(''));
  @override
  // TODO: implement child
  Widget get child
  {
    return PickerMainPage(assetCollection:
    this.assetCollection,type: type,
      photoDidSelectCallBack: photoDidSelectCallBack,maxNumber: maxNumber,
      popCallback: popToDismiss,rootRoute: parentRoute,);

  }

  void popToDismiss()
  {
    var navi = Navigator.of(myContent);
    isCancel = true;
    navi.removeRoute(parentRoute);
    navi.pop();
  }
}

class PickerMainPage extends StatefulWidget
{
  final AssetCollection assetCollection;
  final Route rootRoute;

  final int maxNumber;

  final int type; //0 图片 1 视频 2 音频 -1 所有的

  final AssetPickedCallback photoDidSelectCallBack;

  final PopCallback popCallback;

   PickerMainPage({this.assetCollection,this.maxNumber,
    this.type,this.photoDidSelectCallBack,this.popCallback,
     this.rootRoute});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _PickerMainPage();
  }

}

class _PickerMainPage extends State<PickerMainPage>
{

  List<Map<String,dynamic>> _assetList = [];

  int picSizeWidth;
//  int picSizeHeight;

//  ScrollController _controller = ScrollController();

//  bool needScrollTo = false;

  void requestAssets() async
  {
    try {
      var list = widget.assetCollection.children;
      if(list == null) {
        list = await AssetPicker.getAssetsFromCatalog(widget
            .assetCollection.identifier, widget.type);
      }
      List<Map<String,dynamic>> temp = [];
      for(var asset in list)
      {
        temp.add({'asset':asset,'select':false});
      }
      setState(() {
        _assetList = temp;
//        needScrollTo = true;
      });
    }
    on PlatformException catch(e)
  {
    Toast.show(e.message, context,gravity: Toast.CENTER,backgroundRadius: 8);
    if(int.parse(e.code) == -1000)
      {
        if (widget.popCallback != null) {
          widget.popCallback();
        }
      }
  }
    catch(e)
    {
      Toast.show(e.message, context,gravity: Toast.CENTER,backgroundRadius: 8);

    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestAssets();
  }

  void toBrowser(int index)
  {
    Navigator.of(context).push(

      AssetCupertinoPageRoute(
          builder: (context1)
          {
            return PhotoBrowserPageScaffold(myContent:context,
              assetList: _assetList,
              parentRoute: ModalRoute.of(context),
              rootRoute: widget.rootRoute,
              currentIndex: index,maxNumber: widget.maxNumber,
              photoDidSelectCallBack: widget.photoDidSelectCallBack,);
          }
      )

//        CupertinoPageRoute(
//            builder: (context)
//            {
//              return PhotoBrowserPageScaffold(myContent:context,
//               assetList: _assetList,
//                parentRoute: widget.parentRoute,
//                rootRoute: widget.rootRoute,
//                currentIndex: index,maxNumber: widget.maxNumber,
//                photoDidSelectCallBack: widget.photoDidSelectCallBack,);
//            }
//        )
    );

  }


  Widget getItemCell(int index)
  {
    Asset asset = _assetList[index]['asset'];
    bool isSelect = _assetList[index]['select'];

    int picSizeHeight = (picSizeWidth * asset.ration).toInt();
//    final Widget assetThumb = AssetThumbImage(asset: asset,width:
//    picSizeWidth,height: picSizeHeight,cacheWidth: picSizeWidth,cacheHeight:
//    picSizeHeight,index: index,);
//    Platform.isIOS ? AssetThumbImage(asset: asset,width:
//    picSizeWidth,height: picSizeHeight) : Image
//        .file(File(asset.identifier),
//      width: picSizeWidth.toDouble(),
//      height: picSizeHeight.toDouble(),
//      fit: BoxFit.cover,
//    );

    return Container(
         child:
             Stack(children: <Widget>[

             Container(
                 foregroundDecoration:
                 BoxDecoration(
                   color: isSelect ? Colors.black45 : Colors.transparent
                 )
                 ,

                 child: AssetThumbImage(asset: asset,width:
                 picSizeWidth,height: picSizeHeight,index: index,)
             )
               ,

               Positioned(
                 right: 0,
                 top: 0,
                 width: 30,
                 height: 30,
                 child:
                     Material(

                       color: Colors.transparent, child:

                     Stack(
                       children: <Widget>[
                         Container(
                           margin: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.all(Radius.circular
                                (9)),
                            ),

                         )
                         ,
                         CircleCheckBox
                           (
//                       materialTapTargetSize:MaterialTapTargetSize.padded,
                           activeColor: Colors.green.withOpacity(0.8),
                           value: isSelect,
                           onChanged: (state)
                           {
                             if(state == true)
                             {
                               final int selCount = totalSelect();
                               if(selCount >= widget.maxNumber)
                               {
                                 String typeString = widget.type == 0 ? '照片':
                                 '视频';
                                 Toast.show('最多选择${widget.maxNumber}张$typeString',
                                     context,gravity: Toast.CENTER);
                                 return;
                               }
                             }

                             setState(() {
                               _assetList[index]['select'] = state;
                             });

                           },),
                       ],
                     )
                    ,)

               )

             ],)
     );
  }

  int totalSelect()
  {
    int selCount = 0;
    for(var asset in _assetList)
    {
      if(asset['select'])
      {
        selCount++;
      }
    }
    return selCount;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
   var query = MediaQuery.of(context);
   final double dWidth = query.size.width * query.devicePixelRatio;
   picSizeWidth = dWidth ~/ 3.6;

    final int selCount = totalSelect();

    var subChild = Container(
      child: Column(
        children: <Widget>[
          Expanded(
              child:
              GridView.builder(
//                controller: _controller,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  crossAxisCount: 4,

                ),
                padding: EdgeInsets.fromLTRB(5, 5+MediaQuery.of(context)
                    .padding.top, 5, 8),
                itemBuilder: (BuildContext context, int index) {
                  //Widget Function(BuildContext context, int index)
                  return GestureDetector(
                      onTap: ()
                      {
                        toBrowser(index);
                      },
                      child: getItemCell(index));
                },
                itemCount: _assetList.length,
              )
          ),
          Divider(color: Color(0xFFE5E5E5),height: 1,thickness: 1,),
          Container(
              height: MediaQuery.of(context).padding.bottom + 42,
              alignment: Alignment.topCenter,
              child:
                  Container(
                    height: 42,
                    child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CupertinoButton(
                        padding: EdgeInsets.only(left: 16,right: 16),
                        disabledColor: Color(0xFF226622),
                        onPressed: selCount > 0 ? ()
                        {

                          Navigator.of(context).push(

                              AssetCupertinoPageRoute(
                                  builder: (context1)
                                  {

                                    List<Map<String,dynamic>> selectAssets = [];
                                    for (var asset in _assetList) {
                                      if (asset['select']) {
                                        selectAssets.add(asset);
                                      }
                                    }
                                    return PhotoBrowserPageScaffold(myContent:context,assetList: selectAssets,
                                      currentIndex: 0,maxNumber: widget
                                          .maxNumber,
                                      photoDidSelectCallBack: widget
                                          .photoDidSelectCallBack,
                                      parentRoute: ModalRoute.of(context),
                                      rootRoute: widget.rootRoute,);
                                  }
                              )

//                              CupertinoPageRoute(
//                                  builder: (context)
//                                  {
//
//                                    List<Map<String,dynamic>> selectAssets = [];
//                                    for (var asset in _assetList) {
//                                      if (asset['select']) {
//                                        selectAssets.add(asset);
//                                      }
//                                    }
//                                    return PhotoBrowserPageScaffold(myContent:context,assetList: selectAssets,
//                                      currentIndex: 0,maxNumber: widget
//                                          .maxNumber,
//                                      photoDidSelectCallBack: widget.photoDidSelectCallBack,);
//                                  }
//                              )
                          );

                        }: null,
                        child:
                        Text('预览',
                            style: TextStyle(color: selCount > 0 ? Colors
                                .black87:Colors.black12)),),

                      Container(
                        margin: EdgeInsets.only(right: 16),
                        width: 55,
                        child: CupertinoButton(
                        padding: EdgeInsets.only(
                            left: 5, right: 5, bottom: 2),
                          minSize: 28,
                          borderRadius: const BorderRadius.all(Radius.circular
                            (5.0)),
                          onPressed: selCount > 0 ? () {
                            if (widget.photoDidSelectCallBack != null) {
                              List<Asset> selectAssets = [];
                              for (var asset in _assetList) {
                                if (asset['select']) {
                                  selectAssets.add(asset['asset']);
                                }
                              }
                              widget.photoDidSelectCallBack(selectAssets);
                            }

                            if (widget.popCallback != null) {
                              widget.popCallback();
                            }

                        }: null,
                        color: Colors.lightGreen,
                        disabledColor: Color(0xFF226622),
                        child:
                        Text( selCount > 0 ? '发送($selCount)':'发送',
                            style: TextStyle(fontSize: 12, color: selCount > 0 ?
                            Colors.white:Colors.white70)),),)
                      ,

                    ],
                  ),)
              )
        ],
      ),
    );
    return subChild;
  }

}

