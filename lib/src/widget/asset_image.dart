
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui show Codec;

import '../../asset_picker.dart';

//class _AssetThumbImage extends ImageProvider<_AssetThumbImage> {
//  /// Creates an object that decodes a [File] as an image.
//  ///
//  /// The arguments must not be null.
//  const _AssetThumbImage(this.asset, {this.scale = 1.0,this.quality=100,
//    @required this.width,
//    @required this.height})
//      : assert(asset != null),
//        assert(scale != null);
//
//  /// The file to decode into an image.
//  final Asset asset;
//  final int quality;
//  final int width;
//  final int height;
//  /// The scale to place in the [ImageInfo] object of the image.
//  final double scale;
//
//  @override
//  Future<_AssetThumbImage> obtainKey(ImageConfiguration configuration) {
//    return SynchronousFuture<_AssetThumbImage>(this);
//  }
//
////  @override
////  ImageStreamCompleter load(FileImage key) {
////    return MultiFrameImageStreamCompleter(
////      codec: _loadAsync(key),
////      scale: key.scale,
////      informationCollector: () sync* {
////        yield ErrorDescription('Path: ${file?.path}');
////      },
////    );
////  }
//
//
//  @override
//  ImageStreamCompleter load (_AssetThumbImage key) {
//    return MultiFrameImageStreamCompleter(
//      codec: _loadAsync(key),
//      scale: key.scale,
//      informationCollector: () sync* {
//        yield ErrorDescription('Path: ${asset?.identifier}');
//      },
//    );
//  }
//
//  Future<ui.Codec> _loadAsync(_AssetThumbImage key) async {
//    assert(key == this);
//    final Uint8List assetData = await asset.getImageThumbByteData(width, height);
//    if (assetData == null || assetData
//        .lengthInBytes == 0) {
//
//      return null;
//    }
//    var codec = await PaintingBinding.instance.instantiateImageCodec(assetData);
//   if(codec == null)
//     {
//       return null;
//     }
//    return codec;
//
////    if(Platform.isIOS)
////      {
////        return PaintingBinding.instance.instantiateImageCodec(assetData);
////      }
////    else {
////
////      var codec = await instantiateImageCodec(assetData,
////          targetWidth: width, targetHeight: height);
////      try {
////        codec.getNextFrame().then((data) {
////          try {
////            data.image.toByteData(format: ImageByteFormat.png).then((imageByte) {
////              if(imageByte.lengthInBytes < assetData.data.lengthInBytes)
////                {
////                  Asset.saveThumbCacheBytes(asset.identifier,imageByte.buffer
////                      .asUint8List(),width,height);
////                }
////            });
////          }
////          catch (ex) {
////            print('toByteData frame excption!');
////          }
////        });
////      }
////      catch (ex) {
////        print('getnext frame excption!');
////      }
//
////      return codec;
//
//  }
//
//  @override
//  bool operator ==(dynamic other) {
//    if (other.runtimeType != runtimeType) {
//      return false;
//    }
//    final _AssetThumbImage typedOther = other;
//    bool ret = asset?.identifier == typedOther.asset?.identifier
//        && scale == typedOther.scale && quality == typedOther.quality &&
//        width == typedOther.width && height == typedOther.height;
//    return ret;
//  }
//
//  @override
//  int get hashCode => hashValues(asset?.identifier, scale,width,height,quality);
//
//  @override
//  String toString() => '$runtimeType("${asset?.identifier}", scale: $scale)';
//}
//
//class _AssetOriginalImage extends ImageProvider<_AssetOriginalImage> {
//  /// Creates an object that decodes a [File] as an image.
//  ///
//  /// The arguments must not be null.
//  const _AssetOriginalImage(this.asset, { this.scale = 1.0,this.quality=100})
//      : assert(asset != null),
//        assert(scale != null);
//
//  /// The file to decode into an image.
//  final Asset asset;
//  final int quality;
//  /// The scale to place in the [ImageInfo] object of the image.
//  final double scale;
//
//  @override
//  Future<_AssetOriginalImage> obtainKey(ImageConfiguration configuration) {
//    return SynchronousFuture<_AssetOriginalImage>(this);
//  }
//
//  @override
//  ImageStreamCompleter load(_AssetOriginalImage key) {
//    return MultiFrameImageStreamCompleter(
//      codec: _loadAsync(key),
//      scale: key.scale,
//      informationCollector: () sync* {
//        yield ErrorDescription('Path: ${asset?.identifier}');
//      },
//    );
//  }
//
//  Future<ui.Codec> _loadAsync(_AssetOriginalImage key) async {
//    assert(key == this);
//
//    final Uint8List bytes = await asset.getImageByteData();
//    if (bytes ==null || bytes.lengthInBytes == 0)
//      return null;
//
//    return await PaintingBinding.instance.instantiateImageCodec(bytes);
//  }
//
//  @override
//  bool operator ==(dynamic other) {
//    if (other.runtimeType != runtimeType)
//      return false;
//    final _AssetOriginalImage typedOther = other;
//    return asset?.identifier == typedOther.asset?.identifier
//        && scale == typedOther.scale && quality == typedOther.quality;
//  }
//
//  @override
//  int get hashCode => hashValues(asset?.identifier, scale);
//
//  @override
//  String toString() => '$runtimeType("${asset?.identifier}", scale: $scale)';
//}

class AssetThumbImage extends StatefulWidget {
  /// The asset we want to show thumb for.
  final Asset asset;

  /// The thumb width
  final int width;

  /// The thumb height
  final int height;

  /// The thumb quality
  final int quality;

  /// This is the widget that will be displayed while the
  /// thumb is loading.
  final Widget spinner;
  final int index;

  const AssetThumbImage({
    Key key,
    @required this.asset,
    @required this.width,
    @required this.height,
    this.index,
    this.quality = 80,
    this.spinner,
  }) : super(key: key);

  @override
  _AssetThumbImageState createState() => _AssetThumbImageState();
}

class _AssetThumbImageState extends State<AssetThumbImage> {
  Uint8List _thumbData;

    int get width => widget.width;
    int get height => widget.height;
    int get quality => widget.quality;
    Asset get asset => widget.asset;
    Widget get spinner
    {
      if(widget.spinner == null)
      {
        return  Center(
          child: Container(
             width: widget.width.toDouble(),
            height: widget.height.toDouble(),
            color: Color(0xFFF0F2F5),
          ),
        );
      }
      return widget.spinner;
    }



        @override
        void initState() {

      super.initState();
      this._loadThumb();
    }

    @override
    void didUpdateWidget(AssetThumbImage oldWidget) {
      if (oldWidget.asset.identifier != widget.asset.identifier) {
        this._loadThumb();
      }
      super.didUpdateWidget(oldWidget);
    }

    void _loadThumb() async {
      setState(() {
        _thumbData = null;
      });
      var thumbData = await asset.getImageThumbByteData(
        width,
        height,
        quality: quality,
      );

      if (this.mounted) {
        setState(() {
          _thumbData = thumbData;
        });
      }
    }



    @override
    Widget build(BuildContext context) {

      List<Widget> children = [];
      children.add(Center(
        child: Container(
          width: width.toDouble(),
          height: height.toDouble(),
          color: Color(0xFFF0F2F5),
//          child: Text('my:${widget.index}',style: TextStyle(fontSize:
//          15,color: Colors.yellow),),
        ),
      ),);
      if(_thumbData != null)
        {
          children.add(
              Image.memory(_thumbData,width: width.toDouble(),
            height:height.toDouble(),fit: BoxFit.cover));
        }

      return

        Stack(
          fit: StackFit.expand,
          children:children
//          <Widget>[
//            Center(
//              child: Container(
//                width: widget.width.toDouble(),
//                height: widget.height.toDouble(),
//                color: Color(0xFFF0F2F5),
////          child: Text('my:${widget.index}',style: TextStyle(fontSize:
////          15,color: Colors.yellow),),
//              ),
//            ),
//            Offsetage,
//            _thumbData !=null ? Image.memory(_thumbData,width: width.toDouble(),
//              height:
//            height.toDouble(),fit: BoxFit.cover,) : Container(),
//          ]

        );


  }
}

class AssetOriginalImage extends StatefulWidget {
  /// The asset we want to show original for.
  final Asset asset;

  /// The original quality
  final int quality;
  final BoxFit fit;
  final width;
  final height;


  /// This is the widget that will be displayed while the
  /// original is loading.
  final Widget spinner;
  final picSizeWidth;

   const AssetOriginalImage({
    Key key,
    @required this.asset,
    this.quality = 100,
    this.picSizeWidth = 600,
    this.fit = BoxFit.fill,
     this.width,
     this.height,
    this.spinner = const Center(
      child: SizedBox(
        width: 50,
        height: 50,
//        child: CupertinoActivityIndicator(),
      ),
    ),
  }) : super(key: key);


  @override
  _AssetOriginalImageState createState() => _AssetOriginalImageState();

}


class _AssetOriginalImageState extends State<AssetOriginalImage> {

  Uint8List _originalData;
  Uint8List _thumbData;

  int get quality => widget.quality;
  Asset get asset => widget.asset;
  Widget get spinner => widget.spinner;

  @override
  void initState() {

    super.initState();

    this._loadOriginal();

  }

  @override
  void didUpdateWidget(AssetOriginalImage oldWidget) {
    if (oldWidget.asset.identifier != widget.asset.identifier) {
      this._loadOriginal();
    }
    super.didUpdateWidget(oldWidget);
  }



  Future _loadOriginal() async {
    if (!this.mounted) {
      return;
    }
    setState(() {
        _originalData = null;
        _thumbData = null;
    });

    int picSizeHeight = (widget.picSizeWidth * asset.ration).toInt();

    var thumbData = await asset.getImageThumbByteData(widget
        .picSizeWidth, picSizeHeight,
    );
    if (thumbData != null) {
//      var thumbImage = Image.memory(thumbData, width: double.infinity, height:
//      double.infinity, fit: widget.fit
//        , gaplessPlayback: true,
//      );

      if (!this.mounted) {
        return;
      }

      setState(() {
        _thumbData = thumbData;
      });
    }


    asset.getImageByteData(quality: quality,width: widget.width,height:
    widget.height)
        .then(
            (data) {
              if(data != null) {
                if (this.mounted) {
//                  var originalImage = Image.memory(
//                    data, width: double.infinity, height:
//                  double.infinity, fit: widget.fit,
//                    gaplessPlayback: true,
//                  );
                  setState(() {
                    _originalData = data;
                  });
                }
              }
    });


  }
//
  @override
  Widget build(BuildContext context) {

    if(_thumbData == null && _originalData == null)
      {

        return spinner;
      }
    return
//    return _originalImage ?? _thumbImage;
//      Stack(
//        fit: StackFit.expand,
//        children: <Widget>[
//
//          widget.spinner,
//          FadeInImage(
//            placeholder: _AssetThumbImage(asset, width: widget.picSizeWidth,
//                height:
//                picSizeHeight), image: _AssetOriginalImage(asset),),
//
//        ]
//        ,
//      );

      Image.memory(
      _originalData ?? _thumbData,
      key: ValueKey(asset.identifier),
      fit: widget.fit,
//      width: double.infinity,
//      height: double.infinity,
      gaplessPlayback: true,
    );
  }
}

