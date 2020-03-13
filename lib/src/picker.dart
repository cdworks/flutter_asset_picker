import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:asset_picker/src/asset_model.dart';
import 'package:asset_picker/src/meta_data.dart';
import 'package:flutter/services.dart';

class AssetPicker {
  static const MethodChannel _channel =
      const MethodChannel('asset_picker');

  static Future<List<Asset>>  getAllAsset([int type = 0])  async {

    try {
      final List allAsset = await _channel.invokeMethod('getAllAsset',<String, dynamic>{
        'type': type,
      });
      var assets = List<Asset>();
      for (var item in allAsset) {
        var asset = Asset(
          item['identifier'],
          item['width'],
          item['height'],
        );
        assets.add(asset);
      }
      return assets;
    } catch (e) {
      throw e;
    }
  }


  static Future<List>  getAllAssetCatalog([int type = 0]) async {
    try {
      final List allAsset = await _channel.invokeMethod('getAllAssetCatalog',<String, dynamic>{
        'type': type,
      });
      var assetsCollections = List<AssetCollection>();
      for (var item in allAsset) {
        int count = Platform.isIOS ? item['count'] : item['children'].length;
        var assetsCollection = AssetCollection(
          item['identifier'],
          item['name'],
          count,
        );
        var lastAsset =  item['last'] as Map;
        if(lastAsset.isNotEmpty)
          {
            assetsCollection.lastAsset = Asset(
              lastAsset['identifier'],
              lastAsset['width'],
              lastAsset['height'],
            );
          }
        if(Platform.isAndroid)
          {
            assetsCollection.children = [];
            for(var child in item['children'])
              {
                assetsCollection.children.add(Asset(
                  child['identifier'],
                  child['width'],
                  child['height'],
                ));
              }
          }

        assetsCollections.add(assetsCollection);
      }
      return assetsCollections;
    }catch (e) {
      throw e;
    }
  }

  static Future<List>  getAssetsFromCatalog(String identifier,[int type = 0]) async {
    try {
      final List allAsset = await _channel.invokeMethod('getAssetsFromCatalog',<String, dynamic>{
        'type': type,
        'identifier':identifier
      });
      var assets = List<Asset>();
      for (var item in allAsset) {
        var asset = Asset(
          item['identifier'],
          item['width'],
          item['height'],
        );
        assets.add(asset);
      }
      return assets;
    }catch (e) {
      throw e;
    }
  }


  static Future<Uint8List> requestImageThumbnail(
      String identifier, int width, int height, [int quality = 100]) async {
    assert(identifier != null);
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

    try {
      return await _channel.invokeMethod(
          "requestImageThumbnail", <String, dynamic>{
        "identifier": identifier,
        "width": width,
        "height": height,
        "quality": quality
      });
    }catch (e) {
      print("error:$e");
      return null;
//      throw e;
    }
  }

  /// Requests the original image data for a given
  /// [identifier].
  ///
  /// This method is used by the asset class, you
  /// should not invoke it manually. For more info
  /// refer to [Asset] class docs.
  ///
  /// The actual image data is sent via BinaryChannel.
  static Future<Uint8List> requestImageOriginal(String identifier,{int width,
  int height,
      int quality = 100}) async {
    try {
      if(width == null || height == null)
        {
          return await _channel.invokeMethod(
              "requestImageOriginal", <String, dynamic>{
            "identifier": identifier,
            "quality": quality,
          });
        }
      else {
        return await _channel.invokeMethod(
            "requestImageOriginal", <String, dynamic>{
          "identifier": identifier,
          "quality": quality,
          "width": width,
          "height": height,
        });
      }
    }catch (e) {
      return null;
//      throw e;
    }
  }

  // Requests image metadata for a given [identifier]
  static Future<ImageMetadata> requestImageMetadata(String identifier) async {
    Map<dynamic, dynamic> map = await _channel.invokeMethod(
      "requestImageMetadata",
      <String, dynamic>{
        "identifier": identifier,
      },
    );

    Map<String, dynamic> metadata = Map<String, dynamic>.from(map);
    if (Platform.isIOS) {
      metadata = _normalizeMetadata(metadata);
    }

    return ImageMetadata.fromMap(metadata);
  }

  /// Request a file path for given identifier
  static Future<String> requestFilePath(String identifier) async {
    try {
      String ret =
      await _channel.invokeMethod("requestFilePath", <String, String>{
        "identifier": identifier,
      });
      return ret;
    } catch (e) {
      throw e;
    }
  }

  /// Normalizes the meta data returned by iOS.
  static Map<String, dynamic> _normalizeMetadata(Map<String, dynamic> json) {
    Map map = Map<String, dynamic>();

    json.forEach((String metaKey, dynamic metaValue) {
      if (metaKey == '{Exif}' || metaKey == '{TIFF}') {
        map.addAll(Map<String, dynamic>.from(metaValue));
      } else if (metaKey == '{GPS}') {
        Map gpsMap = Map<String, dynamic>();
        Map<String, dynamic> metaMap = Map<String, dynamic>.from(metaValue);
        metaMap.forEach((String key, dynamic value) {
          if (key == 'GPSVersion') {
            gpsMap['GPSVersionID'] = value;
          } else {
            gpsMap['GPS$key'] = value;
          }
        });
        map.addAll(gpsMap);
      } else {
        map[metaKey] = metaValue;
      }
    });

    return map;
  }

}
