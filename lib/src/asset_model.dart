import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../asset_picker.dart';
import 'meta_data.dart';


/// 判断是否有对应图片缓存文件存在
Future<Uint8List> getFileBytes(String url) async {
  String cacheDirPath = await getCachePath();

  String urlMd5 = getUrlMd5(url);
//  return await compute(_getFileBytes,"$cacheDirPath/$urlMd5");
  File file = File("$cacheDirPath/$urlMd5");
  if (file.existsSync()) {
      return await file.readAsBytes();
  }

  return null;
}

//Future<Uint8List> _getFileBytes(String url) async {
//
//  File file = File(url);
//  if (file.existsSync()) {
//    return await file.readAsBytes();
//  }
//
//  return null;
//}

/// disk cache

/// 获取url字符串的MD5值
String getUrlMd5(String url) {
  var content = new Utf8Encoder().convert(url);
  var digest = md5.convert(content);
  return digest.toString();
}

/// 获取图片缓存路径
Future<String> getCachePath() async {
  Directory dir = await getApplicationDocumentsDirectory();
  Directory cachePath = Directory("${dir.path}/pickasset/imagecache/");
  if (!cachePath.existsSync()) {
    cachePath.createSync(recursive: true);
  }
  return cachePath.path;
}

//class AssetData
//{
//  final bool isThumb;
//  final Uint8List data;
//  const AssetData({this.isThumb,this.data});
//}

class Asset {
  /// The resource identifier
  String _identifier;

  /// The resource file name
//  String _name;

  /// Original image width
  int _originalWidth;

  /// Original image height
  int _originalHeight;

  double ration;

  Asset(
    this._identifier,
//    this._name,
    this._originalWidth,
    this._originalHeight,
  )
  {
    if(_originalWidth ==0 || _originalHeight ==0)
      {
        this.ration = 1;
      }
    else
      {
        this.ration = _originalHeight / _originalWidth;
      }

  }

  /// Returns the original image width
  int get originalWidth {
    return _originalWidth;
  }

  /// Returns the original image height
  int get originalHeight {
    return _originalHeight;
  }

  /// Returns true if the image is landscape
  bool get isLandscape {
    return _originalWidth > _originalHeight;
  }

  /// Returns true if the image is Portrait
  bool get isPortrait {
    return _originalWidth < _originalHeight;
  }

  /// Returns the image identifier
  String get identifier {
    return _identifier;
  }

  /// Returns the image name
//  String get name {
//    return _name;
//  }


  /// Requests a thumbnail for the [Asset] with give [width] and [hegiht].
  ///
  /// The method returns a Future with the [ByteData] for the thumb,
  /// as well as storing it in the _thumbData property which can be requested
  /// later again, without need to call this method again.
  ///
  /// You can also pass the optional parameter [quality] to reduce the quality
  /// and the size of the returned image if needed. The value should be between
  /// 0 and 100. By default it set to 100 (max quality).
  ///
  /// Once you don't need this thumb data it is a good practice to release it,
  /// by calling releaseThumb() method.
  Future<Uint8List> getImageThumbByteData(int width, int height,
      {int quality = 100}) async {
    assert(width != null);
    assert(height != null);

    if (width != null && width < 0) {
      throw new ArgumentError.value(width, 'width cannot be negative');
    }

    if (height != null && height < 0) {
      throw new ArgumentError.value(height, 'height cannot be negative');
    }

    if (quality < 0 || quality > 100) {
      throw new ArgumentError.value(
          quality, 'quality should be in range 0-100');
    }




    Uint8List assetData = await getFileBytes('${_identifier}_${width}_$height');

    if (assetData == null) {
      assetData = await AssetPicker.requestImageThumbnail(
          _identifier, width, height, quality);
      if (Platform.isIOS) {
        if (assetData != null) {
          saveThumbCacheBytes(_identifier, assetData, width, height);
        }
      }
      else {
//        assetData = await File(_identifier).readAsBytes();
        if (assetData == null || assetData.lengthInBytes == 0) {
          print('android get file error!');
          return null;
        }
      }
    }


    return assetData;

//    return completer.future;
  }

  static Future<Uint8List> readFileByte(String path) async
  {
    return  await File(path).readAsBytes();
  }

  static Future saveThumbCacheBytes(String identifier, Uint8List bytes,int
  width,
  int
  height)
  async {
    return await saveBytesToFile('${identifier}_${width}_$height',bytes);
  }


  /// 将下载的图片数据缓存到指定文件
  static Future saveBytesToFile(String url, Uint8List bytes) async {
    if(bytes.length < 10)
      {
        return;
      }
    String cacheDirPath = await getCachePath();

    Directory dir = Directory("$cacheDirPath");
    if(dir.existsSync())
      {
        var fileList = dir.listSync();
        if(fileList.length > 500)
          {
              fileList.sort((FileSystemEntity a, FileSystemEntity b) => a
                  .statSync().accessed
                  .compareTo(b
                  .statSync().accessed));
              for(int i =0 ;i<100;i++)
                {
                  fileList[i].deleteSync();
                }
          }
      }
    
    String urlMd5 = getUrlMd5(url);
    File file = File("$cacheDirPath/$urlMd5");
    if(!file.existsSync()) {
      file.createSync();
      file.writeAsBytes(bytes);
    }
  }



  /// Requests the original image for that asset.
  ///
  /// You can also pass the optional parameter [quality] to reduce the quality
  /// and the size of the returned image if needed. The value should be between
  /// 0 and 100. By default it set to 100 (max quality).
  ///
  /// The method returns a Future with the [ByteData] for the image,
  /// as well as storing it in the _imageData property which can be requested
  /// later again, without need to call this method again.
  Future<Uint8List> getImageByteData({int quality = 100,int width,int height})
  async {
    if (quality < 0 || quality > 100) {
      throw new ArgumentError.value(
          quality, 'quality should be in range 0-100');
    }

//    Completer completer = new Completer<ByteData>();
//    defaultBinaryMessenger.setMessageHandler(_originalChannel,
//        (ByteData message) async {
//      completer.complete(message);
//      defaultBinaryMessenger.setMessageHandler(_originalChannel, null);
//      return message;
//    });
    if(width == 0 || height == 0)
      {
        return await AssetPicker.requestImageOriginal(_identifier,
            quality: quality);
      }
    else {
      return await AssetPicker.requestImageOriginal(_identifier,
          quality: quality, width: width, height: height);
    }
//    return completer.future;
  }

  /// Requests the original image meta data
  Future<ImageMetadata> get metadata {
    return AssetPicker.requestImageMetadata(_identifier);
  }

  /// Requests the original image file path
  Future<String> get filePath {
    return AssetPicker.requestFilePath(_identifier);
  }
}

///A representation of a Photos asset grouping, such as a moment,
/// user-created album, or smart album.

class AssetCollection
{
  String identifier;

  /// The resource file name
  String name;

  /// Original image width
  int count;

  Asset lastAsset; //最后一张图

  List<Asset> children; //android 专用

  AssetCollection(
      this.identifier,
      this.name,
      this.count,
      [this.lastAsset,this.children]
      );
}
