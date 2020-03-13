
import 'package:asset_picker/src/widget/asset_cupertino_page_route.dart';
import 'package:asset_picker/src/widget/asset_image.dart';
import 'package:asset_picker/src/widget/circle_check_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'circle_check_box.dart';

import '../../asset_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'dart:io';

// ignore: must_be_immutable
class PhotoBrowserPageScaffold extends CupertinoPageScaffold with AssetRouteWidget
{
  final List<Map<String,dynamic>> assetList;
  final BuildContext myContent;
  final Route rootRoute;
  final Route parentRoute;
  final int currentIndex;

  final int maxNumber;

  final AssetPickedCallback photoDidSelectCallBack;

//  ObstructingPreferredSizeWidget get navigationBar => CupertinoNavigationBar(
//    middle: const Text('照片'),
//    trailing: CupertinoButton(child: Text('取消'), padding: EdgeInsets.zero,minSize: 30,onPressed: ()
//    {
//      Navigator.of(myContent).pop();
//    },),
//
//  );

  PhotoBrowserPageScaffold({this.assetList,this.myContent,this
      .rootRoute,this.currentIndex = 0,this.photoDidSelectCallBack,this
      .maxNumber,this.parentRoute})
      :super(child:const Text(''));

//  @override
//  // TODO: implement child
  Widget get child
  {
    return GalleryPhotoViewWrapper(
      maxNumber: maxNumber,
      photoDidSelectCallBack: photoDidSelectCallBack,
      galleryItems: assetList,
      backgroundDecoration: const BoxDecoration(
        color: Colors.black,
      ),
      initialIndex: currentIndex,
      scrollDirection: Axis.horizontal,popCallback: popToDismiss,);
  }

  void popToDismiss()
  {
    var navi = Navigator.of(myContent);
    isCancel = true;
    navi.removeRoute(rootRoute);
    navi.removeRoute(parentRoute);

    navi.pop();
  }

}

class GalleryPhotoViewWrapper extends StatefulWidget {
    GalleryPhotoViewWrapper({
    this.loadingChild,
    this.backgroundDecoration,
    this.minScale,
    this.maxScale,
    this.initialIndex,
    this.maxNumber,
    this.photoDidSelectCallBack,
      this.popCallback,
    @required this.galleryItems,
    this.scrollDirection = Axis.horizontal,
  }) : pageController =  PageController(initialPage: initialIndex,keepPage:
    true,viewportFraction: 0.9999);

  final Widget loadingChild;
  final Decoration backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;
  final int initialIndex;
  final PageController pageController;
  final List<Map<String,dynamic>> galleryItems;
  final Axis scrollDirection;
  final int maxNumber;
  final PopCallback popCallback;

  final AssetPickedCallback photoDidSelectCallBack;

  @override
  State<StatefulWidget> createState() {
    return _GalleryPhotoViewWrapperState();
  }


}

class _GalleryPhotoViewWrapperState extends State<GalleryPhotoViewWrapper>
    with SingleTickerProviderStateMixin{
  int currentIndex;
  double picWidth;

  @override
  void initState() {
    currentIndex = widget.initialIndex;
//    picWidth = MediaQuery.of(context).size.width;
    totalSelect();

    controller =
        AnimationController(duration: const Duration(milliseconds: 200), vsync:
        this);
    animation =
        Tween(begin: Offset.zero, end: Offset(0, 1)).animate(controller);
    animationTop = Tween(begin: Offset.zero, end: Offset(0, -1)).animate
      (controller);

    super.initState();


  }

  void totalSelect()
  {
    selCount = 0;
    for(var assetInfo in widget.galleryItems)
      {
        if(assetInfo['select'])
          {
            selCount++;
          }
      }
  }


  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  int selCount = 0;

  AnimationController controller;
  Animation<Offset> animation;
  Animation<Offset> animationTop;

  @override
  Widget build(BuildContext context) {
    var assetInfo = widget.galleryItems[currentIndex];

    return Scaffold(
      body: Container(
        decoration: widget.backgroundDecoration,
        constraints: BoxConstraints.expand(

          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: _buildItem,
              itemCount: widget.galleryItems.length,
              loadingChild: widget.loadingChild,
              backgroundDecoration: widget.backgroundDecoration,
              pageController: widget.pageController,
              onPageChanged: onPageChanged,

              scrollDirection: widget.scrollDirection,
              gaplessPlayback:true,
            ),

            Positioned(
              top: 0,
              left: 0,
              width: MediaQuery.of(context).size.width,
              child:
              SlideTransition(position: animationTop,
                child:
              Container(
                alignment: Alignment.bottomLeft,
              color: const Color(0x99333333),
                padding: EdgeInsets.only(left: 8),
              height: 44 + MediaQuery.of(context).padding.top,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoNavigationBarBackButton(
                      color: Colors.white,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    Text(
                      "${currentIndex + 1} / ${widget.galleryItems.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17.0,
                        decoration: null,
                      ),
                    ),
                    CircleCheckBox(
                      activeColor: Colors.green,
                      materialTapTargetSize:MaterialTapTargetSize.padded,
                      onChanged: (state)
                      {
                        if(state == true)
                        {
                          if(selCount >= widget.maxNumber)
                          {
                            Toast.show('最多选择${widget.maxNumber}张照片',
                                context,gravity: Toast.CENTER,backgroundRadius: 8);
                            return;
                          }
                        }

                        setState(() {
                          selCount += state ? 1 : -1;
                          assetInfo['select'] = state;
                        });

                      },
                      value: assetInfo['select'],

                    )
                  ],
                ),
            ),
              )
            ),

            Positioned(
                bottom: 0,
                right: 0,
                height: 44 + MediaQuery.of(context).padding.bottom,
                width: MediaQuery.of(context).size.width,
                child:
                SlideTransition(position: animation,
                child:
                Container(
                  alignment: Alignment.topLeft,
                  color: const Color(0x99333333),
                  child: Container(
                    height: 44,
                    child: Stack(
                      children: <Widget>[
                        Center(child: Text('已选择（$selCount）', style: TextStyle
                          (color: Colors.white, fontSize: 17),),),
                        Align(
                          alignment: Alignment.centerRight,
                          child:
                          CupertinoButton(
                            padding: EdgeInsets.only(right: 16, left: 8),
                            child: Text('完成', style: TextStyle
                              (color: Colors.white)),
                            onPressed: () {

                              if (widget.photoDidSelectCallBack != null) {
                                List<Asset> selectAssets = [];
                                for (var asset in widget.galleryItems) {
                                  if (asset['select']) {
                                    selectAssets.add(asset['asset']);
                                  }
                                }
                                if(selectAssets.isEmpty)
                                  {
                                    selectAssets.add(widget
                                        .galleryItems[currentIndex]['asset']);
                                  }
                                widget.photoDidSelectCallBack(selectAssets);
                              }

                              if (widget.popCallback != null) {
                                widget.popCallback();
                              }

                            },
                          ),)
                      ],
                    ),
                  ),
                )
                )
            ),
          ],
        ),
      ),
    );
  }

  PhotoViewGalleryPageOptions _buildItem(BuildContext context, int index)  {
    final Map<String, dynamic> item = widget.galleryItems[index];
    Asset asset = item['asset'];

    Widget assetChild;
//    if(Platform.isIOS)
//    {
      int width = asset.originalWidth;
      int height = asset.originalHeight;
      if(width > 4000)
      {
        width = 4000;
        height = (width * asset.ration).toInt();
      }
      else if(height >4000)
      {
        height = 4000;
        double dHeight = (height / asset.ration);
        height = dHeight.toInt();
      }
      var query = MediaQuery.of(context);
      var picWidth = query.size.width * query.devicePixelRatio;


      assetChild = AssetOriginalImage(
        asset: asset,
        fit: BoxFit.contain,
        picSizeWidth: picWidth ~/3.6,
        quality: 80,
        width: width == asset.originalWidth ? 0: width,
        height: height == asset.originalHeight ? 0: height,
      );
//    }
//    else
//    {
//      assetChild = Image.file(File(asset.identifier));
//    }

    return
      PhotoViewGalleryPageOptions.customChild(
      child: Container(
//        width: asset.originalWidth.toDouble(),
//        height: asset.originalHeight.toDouble(),
        child: assetChild
      ),
      onTapUp: (BuildContext context,
          TapUpDetails details,
          PhotoViewControllerValue controllerValue,)
        {
          if(!controller.isAnimating)
            {
              if(controller.status == AnimationStatus.completed) {
                controller.reverse();
              }
              else if(controller.status == AnimationStatus.dismissed)
                {
                  controller.forward();
                }
            }


        },
      childSize: Size(MediaQuery.of(context).size.width,MediaQuery.of(context)
          .size.height),
      initialScale: PhotoViewComputedScale.contained,
      minScale:
      PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * 3.5,
      heroAttributes: PhotoViewHeroAttributes(tag: asset.identifier),

    );
//        :
//    return PhotoViewGalleryPageOptions(
//      imageProvider: MemoryImage(await asset.getImageByteData()),
//      initialScale: PhotoViewComputedScale.contained,
//      minScale: PhotoViewComputedScale.contained * (0.5 + index / 10),
//      maxScale: PhotoViewComputedScale.covered * 1.1,
//      heroAttributes: PhotoViewHeroAttributes(tag: asset.identifier),
//    );
  }
}


