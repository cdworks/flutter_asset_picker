#import "AssetPickerPlugin.h"

//@implementation PHAsset (flutter)
//
//-(NSString*)originalFilename
//{
//    NSString* fileName = @"";
//    if (@available(iOS 9.0, *)) {
//        NSArray<PHAssetResource *> * resources = [PHAssetResource assetResourcesForAsset:self];
//        if (resources.count) {
//            fileName = resources.firstObject.originalFilename;
//        }
//    } else {
//        fileName = [self valueForKeyPath:@"filename"];
//    }
//    return fileName;
//}
//
//@end

@interface AssetPickerPlugin()

@property(nonatomic,weak)FlutterViewController* controller;
@property(nonatomic,weak)NSObject<FlutterBinaryMessenger>* messenger;
@property(nonatomic,strong)PHImageManager* manager;

@end

@implementation AssetPickerPlugin

-(instancetype)initWithController:(FlutterViewController*)controller messenger:(NSObject<FlutterBinaryMessenger>*)messenger
{
    self = [super init];
    if (self) {
        _controller = controller;
        _messenger = messenger;
        _manager = [PHImageManager defaultManager];
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [PHImageManager defaultManager];
    }
    return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"asset_picker"
                                     binaryMessenger:[registrar messenger]];

//    FlutterViewController* controller = (FlutterViewController*)UIApplication.sharedApplication.delegate.window.rootViewController;


    AssetPickerPlugin* instance = [[AssetPickerPlugin alloc] init];
//    [[AssetPickerPlugin alloc] initWithController:controller messenger:registrar.messenger];
    [registrar addMethodCallDelegate:instance channel:channel];


}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getAllAsset" isEqualToString:call.method]) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if(status == PHAuthorizationStatusAuthorized)
                {
                    NSDictionary* arguments = call.arguments;
                    NSInteger type = [[arguments valueForKeyPath:@"type"] integerValue];

                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", type == 0 ? PHAssetMediaTypeImage : PHAssetMediaTypeVideo];

                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                    PHFetchResult* assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];

                    NSMutableArray* results = [NSMutableArray arrayWithCapacity:assetsFetchResults.count];
                    for (PHAsset * obj in assetsFetchResults) {
                        [results addObject:@{@"identifier": obj.localIdentifier,
                                             @"width": @(obj.pixelWidth),
                                             @"height":@(obj.pixelHeight),
//                                             @"name": obj.originalFilename
                        }];
                    }
                    result(results);
                }
                else if(status == PHAuthorizationStatusDenied)
                {
                    result([FlutterError errorWithCode:@"-1" message:@"用户拒绝访问相册!" details:nil]);
                    return;
                }
                else if(status == PHAuthorizationStatusRestricted)
                {
                    result([FlutterError errorWithCode:@"-2" message:@"因系统原因，无法访问相册！" details:nil]);
                    return;
                }
                result([FlutterError errorWithCode:@"-3" message:@"用户未选择权限" details:nil]);
                return;
        }];

//        result([FlutterError errorWithCode:@"-3" message:@"用户未选择权限" details:nil]);



    }
    else if ([@"getAllAssetCatalog" isEqualToString:call.method]) {

        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if(status == PHAuthorizationStatusAuthorized)
                {
                    NSDictionary* arguments = call.arguments;
                    NSInteger type = [[arguments valueForKeyPath:@"type"] integerValue];

                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", type == 0 ? PHAssetMediaTypeImage : PHAssetMediaTypeVideo];

                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
                    PHFetchResult<PHAsset*>* allFetchResults = [PHAsset fetchAssetsWithOptions:options];


                    NSMutableArray* results = [NSMutableArray arrayWithObject:@{@"name":@"所有照片",@"identifier":@"all_identifier",@"count":@(allFetchResults.count),@"last":allFetchResults.count ? @{@"identifier": allFetchResults.lastObject.localIdentifier,
                        @"width": @(allFetchResults.lastObject.pixelWidth),
                        @"height":@(allFetchResults.lastObject.pixelHeight),
                    }: @{}}];
                    PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                    // 这时 smartAlbums 中保存的应该是各个智能相册对应的 PHAssetCollection
                    for (NSInteger i = 0; i < fetchResult.count; i++) {
                        // 获取一个相册（PHAssetCollection）
                        PHCollection *collection = fetchResult[i];
                        if ([collection isKindOfClass:[PHAssetCollection class]]) {

                            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                            PHAssetCollectionSubtype subType = assetCollection.assetCollectionSubtype;
                            if  (subType < 300 && subType != PHAssetCollectionSubtypeSmartAlbumAllHidden && subType != PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                                if (!type) {
                                    if (subType != PHAssetCollectionSubtypeSmartAlbumVideos && subType != PHAssetCollectionSubtypeSmartAlbumSlomoVideos) {
                                        //                                 AssetCollectionModel* collectionModel = [AssetCollectionModel new];
                                        //                                 collectionModel.name = assetCollection.localizedTitle;

                                        // 从每一个智能相册中获取到的 PHFetchResult 中包含的才是真正的资源（PHAsset）
                                        PHFetchResult<PHAsset*> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                                        [results addObject:@{@"name":assetCollection.localizedTitle,@"identifier":assetCollection.localIdentifier,@"count":@(fetchResult.count),@"last":fetchResult.count ? @{@"identifier": fetchResult.lastObject.localIdentifier,
                                        @"width": @(fetchResult.lastObject.pixelWidth),
                                        @"height":@(fetchResult.lastObject.pixelHeight),
                                        } : @{}}];
                                    }
                                }
                                else
                                {
                                    if (subType == PHAssetCollectionSubtypeSmartAlbumSlomoVideos) {


                                        // 从每一个智能相册中获取到的 PHFetchResult 中包含的才是真正的资源（PHAsset）
                                        PHFetchResult<PHAsset*> *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                                        [results addObject:@{@"name":assetCollection.localizedTitle,@"identifier":assetCollection.localIdentifier,@"count":@(fetchResult.count),@"last":fetchResult.count ? @{@"identifier": fetchResult.lastObject.localIdentifier,
                                        @"width": @(fetchResult.lastObject.pixelWidth),
                                        @"height":@(fetchResult.lastObject.pixelHeight),
                                        } : @{}}];
                                    }
                                }

                            }
                            else
                            {
                                NSLog(@"Fetch collection not PHCollection");
                            }
                        }
                    }
                    result(results);
                }
                else if(status == PHAuthorizationStatusDenied)
                {
                    result([FlutterError errorWithCode:@"-1" message:@"用户拒绝访问相册!" details:nil]);
                    return;
                }
                else if(status == PHAuthorizationStatusRestricted)
                {
                    result([FlutterError errorWithCode:@"-2" message:@"因系统原因，无法访问相册！" details:nil]);
                    return;
                }
                result([FlutterError errorWithCode:@"-3" message:@"用户未选择权限" details:nil]);
                return;
        }];

    }
    else if ([@"getAssetsFromCatalog" isEqualToString:call.method]) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status == PHAuthorizationStatusAuthorized)
            {
                NSDictionary* arguments = call.arguments;
                        NSInteger type = [[arguments valueForKeyPath:@"type"] integerValue];
                        NSString* identifier = [arguments valueForKeyPath:@"identifier"];

                        if (identifier.length) {

                            if ([identifier isEqualToString:@"all_identifier"]) {
                                PHFetchOptions *options = [[PHFetchOptions alloc] init];
                                options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", type == 0 ? PHAssetMediaTypeImage : PHAssetMediaTypeVideo];

                                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];

                                PHFetchResult<PHAsset *>* assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
                                NSMutableArray* results = [NSMutableArray arrayWithCapacity:assetsFetchResults.count];
                                for (PHAsset * obj in assetsFetchResults) {
                                    [results addObject:@{@"identifier": obj.localIdentifier,
                                                         @"width": @(obj.pixelWidth),
                                                         @"height":@(obj.pixelHeight),
                //                                         @"name": obj.originalFilename
                                    }];
                                }
                                result(results);
                            }
                            else
                            {
                                PHFetchResult<PHAssetCollection *> * collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[identifier] options:nil];

                                if (collections.count) {

                                    PHFetchOptions *options = [[PHFetchOptions alloc] init];
                                    options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", type == 0 ? PHAssetMediaTypeImage : PHAssetMediaTypeVideo];

                                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                                    PHFetchResult<PHAsset *>* assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:collections.firstObject options:options];

                                    NSMutableArray* results = [NSMutableArray arrayWithCapacity:assetsFetchResults.count];
                                    for (PHAsset * obj in assetsFetchResults) {
                                        [results addObject:@{@"identifier": obj.localIdentifier,
                                                             @"width": @(obj.pixelWidth),
                                                             @"height":@(obj.pixelHeight),
                //                                             @"name": obj.originalFilename
                                        }];
                                    }
                                    result(results);

                                }
                                else
                                {
                                    result([FlutterError errorWithCode:@"-2" message:@"The PHFetchOptions does not exist" details:nil]);
                                }

                            }


                        }
                        else
                        {
                            result([FlutterError errorWithCode:@"-1" message:@"identifier == null" details:nil]);
                        }
            }
        }];
        

    }
    else if ([@"requestImageThumbnail" isEqualToString:call.method]) {

        NSDictionary* arguments = call.arguments;
        NSString* identifier = arguments[@"identifier"];
        NSInteger width = [arguments[@"width"] integerValue];
        NSInteger height = [arguments[@"height"] integerValue];
        NSInteger quality = [arguments[@"quality"] integerValue];
        if (identifier.length) {
            PHImageRequestOptions* options = [PHImageRequestOptions new];
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.synchronous = YES;
            PHFetchResult<PHAsset *>* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
            if (assets.count) {
                PHImageRequestID ID = [_manager requestImageForAsset:assets.firstObject targetSize:CGSizeMake(width, height) contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                    if (image) {
//                        result(UIImagePNGRepresentation(image));
                            result(UIImageJPEGRepresentation(image, ((CGFloat)quality)/100.f));

                    }
                    else
                    {
                        result([FlutterError errorWithCode:@"-3" message:@"The requested image does not exist." details:nil]);
                    }
                }];
                if (ID == PHInvalidImageRequestID) {
                    result([FlutterError errorWithCode:@"-3" message:@"The requested image does not exist." details:nil]);
                }
            }
            else
            {
                result([FlutterError errorWithCode:@"-2" message:@"The requested image does not exist." details:nil]);
            }
        }
        else
        {
            result([FlutterError errorWithCode:@"-1" message:@"identifier == null" details:nil]);
        }
    }
    else if ([@"requestImageOriginal" isEqualToString:call.method]) {

        NSDictionary* arguments = call.arguments;
        NSString* identifier = arguments[@"identifier"];
        NSInteger quality = [arguments[@"quality"] integerValue];

        if (identifier.length) {
            PHImageRequestOptions* options = [PHImageRequestOptions new];
            options.networkAccessAllowed = YES;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.synchronous = false;
            options.version = PHImageRequestOptionsVersionCurrent;

            PHFetchResult<PHAsset *>* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil];
            if (assets.count) {
                CGSize targetSize = PHImageManagerMaximumSize;
                if([arguments objectForKey:@"width"])
                {
                    targetSize = CGSizeMake([[arguments objectForKey:@"width"] floatValue], [[arguments objectForKey:@"height"] floatValue]);
                }
                PHImageRequestID ID = [_manager requestImageForAsset:assets.firstObject targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable image, NSDictionary * _Nullable info) {
                    if (image) {
                        result(UIImageJPEGRepresentation(image, ((CGFloat)quality)/100.f));
                    }
                    else
                    {
                        result([FlutterError errorWithCode:@"-3" message:@"The requested image does not exist." details:nil]);
                    }
                }];
                if (ID == PHInvalidImageRequestID) {
                    result([FlutterError errorWithCode:@"-3" message:@"The requested image does not exist." details:nil]);
                }
            }
            else
            {
                result([FlutterError errorWithCode:@"-2" message:@"The requested image does not exist." details:nil]);
            }
        }
        else
        {
            result([FlutterError errorWithCode:@"-1" message:@"identifier == null" details:nil]);
        }
    }
    else if ([@"requestImageMetadata" isEqualToString:call.method]) {
    }
    //  else if ([@"requestFilePath" isEqualToString:call.method]) {
    //  }
    //
    else {
        result(FlutterMethodNotImplemented);
    }
}



@end
