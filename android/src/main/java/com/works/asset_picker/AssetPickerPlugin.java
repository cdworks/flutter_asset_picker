package com.works.asset_picker;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Message;
import android.provider.ContactsContract;
import android.provider.MediaStore;
import android.text.TextUtils;
import android.util.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import java.io.*;
import java.lang.ref.WeakReference;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import static android.media.ThumbnailUtils.OPTIONS_RECYCLE_INPUT;

/**
 * AssetPickerPlugin
 */
public class AssetPickerPlugin implements MethodChannel.MethodCallHandler,
        PluginRegistry.RequestPermissionsResultListener {

    //  private final MethodChannel channel;
    private final Activity activity;
    private final Context context;
    //  private final BinaryMessenger messenger;
    private MethodChannel.Result pendingResult;
    private MethodCall methodCall;

    private Map<String,Object> permissionRequest;

    private static final int REQUEST_CODE_GRANT_PERMISSIONS_ASSET_ALL = 2001;
    private static final int REQUEST_CODE_GRANT_PERMISSIONS_ASSET_COLLECTION = 2002;

    //创建基本线程池
    final ThreadPoolExecutor threadPoolExecutor = new ThreadPoolExecutor(
            10, 28, 1,
            TimeUnit.SECONDS,
            new LinkedBlockingQueue<Runnable>(50), new ThreadPoolExecutor.DiscardOldestPolicy());

    //创建基本线程池
    final ThreadPoolExecutor threadPoolExecutorCache = new ThreadPoolExecutor(
            10, 28, 1,
            TimeUnit.SECONDS,
            new LinkedBlockingQueue<Runnable>(50), new ThreadPoolExecutor.DiscardOldestPolicy());

    //判断文件是否存在
    static public File fileIsExists(String strFile) {
        try {
            File file = new File(strFile);
            if (file.exists()) {
                return file;
            }
        } catch (Exception e) {
            return null;
        }
        return null;
    }

    public static String encryptToMd5(String str) {
        String hexStr = "";
        try {
            byte[] bytes = MessageDigest.getInstance("MD5").digest(str.getBytes("UTF-8"));
            for (byte b : bytes) {
                String temp = Integer.toHexString(b & 0xff);
                if (temp.length() == 1) {
                    temp = "0" + temp;
                }
                hexStr += temp;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return hexStr;
    }

    String getCachePath() {
        String dirPath = activity.getDir("flutter", Context.MODE_PRIVATE).getPath() + "/pickasset/imagecache";
        return dirPath;
    }

    /**
     * 将InputStream转换成byte数组
     *
     * @param in InputStream
     * @return byte[]
     * @throws IOException
     */
    public static byte[] inputStreamTOByte(InputStream in) throws IOException {

        ByteArrayOutputStream outStream = new ByteArrayOutputStream();
        byte[] data = new byte[4096];
        int count = -1;
        while ((count = in.read(data, 0, 4096)) != -1)
            outStream.write(data, 0, count);
        data = outStream.toByteArray();
        outStream.close();
        return data;
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "asset_picker");

        AssetPickerPlugin instance = new AssetPickerPlugin(registrar.activity(), registrar.context());
        registrar.addRequestPermissionsResultListener(instance);
        channel.setMethodCallHandler(instance);
    }

    private AssetPickerPlugin(Activity activity, Context context) {
        this.activity = activity;
        this.context = context;
        permissionRequest = new HashMap<>();
//    this.channel = channel;
//    this.messenger = messenger;
    }

    @Override
    public void onMethodCall(MethodCall call, final MethodChannel.Result result) {

        this.methodCall = call;
        this.pendingResult = result;

        if (call.method.equals("getAllAssetCatalog")) {
            if (requestPermission(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_ALL)) {
                getAllAssetCatalog();
            }
        } else if (call.method.equals("getAssetsFromCatalog")) {

            Map arguments = (Map) this.methodCall.arguments;

            String foldPath = (String) arguments.get("identifier");
            if (foldPath.equals("all_identifier"))  //全部照片
            {
                if (requestPermission(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_COLLECTION)) {
                    getAssetsFromCatalog();
                }
            } else {
                result.error("-1", "参数错误!", null);
                clearMethodCallAndResult();
            }
        } else if (call.method.equals("requestImageThumbnail")) {
            clearMethodCallAndResult();
            Map arguments = (Map) call.arguments;

            final String path = (String) arguments.get("identifier");

            final int width = ((int) arguments.get("width"));
            final int height = ((int) arguments.get("height"));
            final int quality = ((int) arguments.get("quality"));

            try {
                threadPoolExecutor.execute(new Runnable() {
                    @Override
                    public void run() {

                        try {
                            // get a reference to the activity if it is still there
                            final String thumbPath = getCachePath() + "/" + AssetPickerPlugin.encryptToMd5(path + "_" + width + "_" + height);
                            File thumbFile = AssetPickerPlugin.fileIsExists(thumbPath);
                            if (thumbFile != null) {
                                final Uri thumbUri = Uri.fromFile(thumbFile);
                                final InputStream is = activity.getContentResolver().openInputStream(thumbUri);
//            Bitmap thumbBitmap = BitmapFactory.decodeStream(is);
//            ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                                final byte[] thumbByte = AssetPickerPlugin.inputStreamTOByte(is);
                                is.close();
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(thumbByte);
                                    }
                                });

                                return;
//              return byteArray;
                            }

                            File originalFile = new File(path);


                            int orientation = getOrientation(context, path);

                            InputStream inStream = activity.getContentResolver().openInputStream(Uri.fromFile(originalFile));
                            Bitmap sourceBitmap;
//                      BitmapFactory.decodeStream(inStream);
                            try {
                                sourceBitmap = getFitSampleBitmap(inStream, true, width, height);
                            } catch (Exception e) {
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.error("-5", "读取文件错误", null);
                                    }
                                });
                                return;
                            }


//                Bitmap bitmap = ThumbnailUtils.extractThumbnail(sourceBitmap, width, height);


                            if (orientation > 0) {
                                Matrix matrix = new Matrix();
                                matrix.postRotate(orientation);
                                Bitmap temp = Bitmap.createBitmap(sourceBitmap, 0, 0, sourceBitmap.getWidth(),
                                        sourceBitmap.getHeight(), matrix, true);
                                sourceBitmap.recycle();
                                sourceBitmap = temp;
//                    bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(),
//                            bitmap.getHeight(), matrix, true);
                            }


                            if (sourceBitmap == null) {
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.error("-5", "读取文件错误", null);
                                    }
                                });

                                return;
                            }

                            ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                            sourceBitmap.compress(Bitmap.CompressFormat.JPEG, quality, bitmapStream);

                            final FileOutputStream fs = new FileOutputStream(thumbPath);

                            bitmapStream.writeTo(fs);


                            threadPoolExecutorCache.execute(new Runnable() {
                                @Override
                                public void run() {
                                    try {
                                        fs.flush();
                                        fs.close();
                                    } catch (IOException e) {
                                        e.printStackTrace();
                                    }
                                }
                            });


                            final byte[] byteArray = bitmapStream.toByteArray();
                            sourceBitmap.recycle();
                            bitmapStream.close();
                            activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.success(byteArray);
                                }
                            });

                        } catch (IOException e) {
                            e.printStackTrace();
                            activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    result.error("-5", "读取文件错误", null);
                                }
                            });
                            return;
                        }


//      final ByteBuffer buffer;
//      if (byteArray != null) {
//        buffer = ByteBuffer.allocateDirect(byteArray.length);
//        buffer.put(byteArray);
//        return buffer;
//      }

                    }
                });
            } catch (Exception ex) {
                ex.printStackTrace();
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        result.error("-5", "读取文件错误", null);
                    }
                });

//        result.error("-5", "读取文件错误", null);
            }

//      GetThumbnailTask task = new GetThumbnailTask(this.activity, this.threadPoolExecutor, result, path, width, height, quality);
//      task.execute();
//      clearMethodCallAndResult();

        } else if (call.method.equals("requestImageOriginal")) {
            clearMethodCallAndResult();
            final Map arguments = (Map) call.arguments;
            final String path = (String) arguments.get("identifier");
            final int quality = ((int) arguments.get("quality"));
            if (arguments.get("width") != null) {
                final int width = ((int) arguments.get("width"));
                final int height = ((int) arguments.get("height"));

                try {
                    threadPoolExecutor.execute(new Runnable() {
                        @Override
                        public void run() {

                            try {
                                // get a reference to the activity if it is still there
                                final String thumbPath = getCachePath() + "/" + AssetPickerPlugin.encryptToMd5(path + "_" + width + "_" + height);
                                File thumbFile = AssetPickerPlugin.fileIsExists(thumbPath);
                                if (thumbFile != null) {
                                    final Uri thumbUri = Uri.fromFile(thumbFile);
                                    final InputStream is = activity.getContentResolver().openInputStream(thumbUri);
//            Bitmap thumbBitmap = BitmapFactory.decodeStream(is);
//            ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                                    final byte[] thumbByte = AssetPickerPlugin.inputStreamTOByte(is);
                                    is.close();
                                    activity.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.success(thumbByte);
                                        }
                                    });

                                    return;
//              return byteArray;
                                }

                                File originalFile = new File(path);


                                int orientation = getOrientation(context, path);

                                InputStream inStream = activity.getContentResolver().openInputStream(Uri.fromFile(originalFile));
                                Bitmap sourceBitmap;
//                      BitmapFactory.decodeStream(inStream);
                                try {
                                    sourceBitmap = getFitSampleBitmap(inStream, true, width, height);
                                } catch (Exception e) {
                                    activity.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.error("-5", "读取文件错误", null);
                                        }
                                    });
                                    return;
                                }


//                Bitmap bitmap = ThumbnailUtils.extractThumbnail(sourceBitmap, width, height);
//                sourceBitmap.recycle();


                                if (orientation > 0) {
                                    Matrix matrix = new Matrix();
                                    matrix.postRotate(orientation);
                                    Bitmap temp = Bitmap.createBitmap(sourceBitmap, 0, 0, sourceBitmap.getWidth(),
                                            sourceBitmap.getHeight(), matrix, true);
                                    sourceBitmap.recycle();
                                    ;
                                    sourceBitmap = temp;
                                }


                                if (sourceBitmap == null) {
                                    activity.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.error("-5", "读取文件错误", null);
                                        }
                                    });

                                    return;
                                }

                                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                                sourceBitmap.compress(Bitmap.CompressFormat.JPEG, quality, bitmapStream);

                                final FileOutputStream fs = new FileOutputStream(thumbPath);

                                bitmapStream.writeTo(fs);


                                threadPoolExecutorCache.execute(new Runnable() {
                                    @Override
                                    public void run() {
                                        try {
                                            fs.flush();
                                            fs.close();
                                        } catch (IOException e) {
                                            e.printStackTrace();
                                        }
                                    }
                                });


                                final byte[] byteArray = bitmapStream.toByteArray();
                                sourceBitmap.recycle();
                                bitmapStream.close();
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(byteArray);
                                    }
                                });

                            } catch (IOException e) {
                                e.printStackTrace();
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.error("-5", "读取文件错误", null);
                                    }
                                });
                                return;
                            }


//      final ByteBuffer buffer;
//      if (byteArray != null) {
//        buffer = ByteBuffer.allocateDirect(byteArray.length);
//        buffer.put(byteArray);
//        return buffer;
//      }

                        }
                    });
                } catch (Exception ex) {
                    ex.printStackTrace();
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            result.error("-5", "读取文件错误", null);
                        }
                    });
//          result.error("-5", "读取文件错误", null);
                }
            } else {
                try {
                    threadPoolExecutor.execute(new Runnable() {
                        @Override
                        public void run() {

                            try {

                                File originalFile = new File(path);


                                int orientation = getOrientation(context, path);

                                InputStream inStream = activity.getContentResolver().openInputStream(Uri.fromFile(originalFile));
                                Bitmap sourceBitmap;
//                      BitmapFactory.decodeStream(inStream);
                                try {
                                    sourceBitmap = getFitSampleBitmap(inStream, false, -1, -1);
                                } catch (Exception e) {
                                    activity.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.error("-5", "读取文件错误", null);
                                        }
                                    });
                                    return;
                                }


                                if (orientation > 0) {
                                    Matrix matrix = new Matrix();
                                    matrix.postRotate(orientation);
                                    Bitmap temp = Bitmap.createBitmap(sourceBitmap, 0, 0, sourceBitmap.getWidth(),
                                            sourceBitmap.getHeight(), matrix, true);
                                    sourceBitmap.recycle();
                                    sourceBitmap = temp;
                                }


                                if (sourceBitmap == null) {
                                    activity.runOnUiThread(new Runnable() {
                                        @Override
                                        public void run() {
                                            result.error("-5", "读取文件错误", null);
                                        }
                                    });

                                    return;
                                }

                                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                                sourceBitmap.compress(Bitmap.CompressFormat.JPEG, quality, bitmapStream);


                                final byte[] byteArray = bitmapStream.toByteArray();
                                sourceBitmap.recycle();
                                bitmapStream.close();
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.success(byteArray);
                                    }
                                });

                            } catch (IOException e) {
                                e.printStackTrace();
                                activity.runOnUiThread(new Runnable() {
                                    @Override
                                    public void run() {
                                        result.error("-5", "读取文件错误", null);
                                    }
                                });
                                return;
                            }


//      final ByteBuffer buffer;
//      if (byteArray != null) {
//        buffer = ByteBuffer.allocateDirect(byteArray.length);
//        buffer.put(byteArray);
//        return buffer;
//      }

                        }
                    });
                } catch (Exception ex) {
                    ex.printStackTrace();
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            result.error("-5", "读取文件错误", null);
                        }
                    });
//          result.error("-5", "读取文件错误", null);
                }
            }


        } else {
            result.notImplemented();
            clearMethodCallAndResult();
        }
    }

    public static Bitmap getFitSampleBitmap(InputStream inputStream, boolean needSampleSize, int width, int height) throws Exception {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        byte[] bytes = readStream(inputStream);
        BitmapFactory.decodeByteArray(bytes, 0, bytes.length, options);
        options.inSampleSize = (needSampleSize && width > 0 || height > 0) ? Math.max(2, calculateInSampleSize(options, width, height)) : 1;
        options.inJustDecodeBounds = false;
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.length, options);
    }


    public static int calculateInSampleSize(
            BitmapFactory.Options options, int reqWidth, int reqHeight) {
        // Raw height and width of image
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > reqHeight || width > reqWidth) {

            final int halfHeight = height / 2;
            final int halfWidth = width / 2;

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while ((halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        return inSampleSize;
    }

    /**
     * 从inputStream中获取字节流 数组大小
     **/
    public static byte[] readStream(InputStream inStream) throws Exception {
        ByteArrayOutputStream outStream = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int len = 0;
        while ((len = inStream.read(buffer)) != -1) {
            outStream.write(buffer, 0, len);
        }
        outStream.close();
        inStream.close();
        return outStream.toByteArray();
    }

//    private boolean uriExists(String identifier) {
//        Uri uri = Uri.parse(identifier);
//
////        String fileName = this.getFileName(uri);
//
//        return (uri != null);
//    }


    private static class GetThumbnailTask extends AsyncTask<String, Void, byte[]> {
        private WeakReference<Activity> activityReference;
        private WeakReference<ThreadPoolExecutor> threadPoolExecutorWeakReference;
        MethodChannel.Result pendingResult;
        final String identifier;
        final int width;
        final int height;
        final int quality;


        GetThumbnailTask(Activity context, ThreadPoolExecutor executor, MethodChannel.Result pendingResult, String identifier, int width, int height, int quality) {
            super();
            this.pendingResult = pendingResult;
            this.identifier = identifier;
            this.width = width;
            this.height = height;
            this.quality = quality;
            this.activityReference = new WeakReference<>(context);
            this.threadPoolExecutorWeakReference = new WeakReference<>(executor);
        }

        String getCachePath() {
            Activity activity = activityReference.get();

            String dirPath = activity.getDir("flutter", Context.MODE_PRIVATE).getPath() + "/pickasset/imagecache";
            return dirPath;
        }

        @Override
        protected byte[] doInBackground(String... strings) {
            byte[] byteArray = null;

            try {
                // get a reference to the activity if it is still there

                Activity activity = activityReference.get();


                if (activity == null || activity.isFinishing()) return null;
                final String thumbPath = getCachePath() + "/" + AssetPickerPlugin.encryptToMd5(identifier + "_" + width + "_" + height);
                File thumbFile = AssetPickerPlugin.fileIsExists(thumbPath);
                if (thumbFile != null) {
                    final Uri thumbUri = Uri.fromFile(thumbFile);
                    InputStream is = activity.getContentResolver().openInputStream(thumbUri);
//            Bitmap thumbBitmap = BitmapFactory.decodeStream(is);
//            ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                    byteArray = AssetPickerPlugin.inputStreamTOByte(is);
                    is.close();
                    return byteArray;
                }

                File originalFile = new File(identifier);
                Bitmap sourceBitmap = BitmapFactory.decodeStream(activity.getContentResolver().openInputStream(Uri.fromFile(originalFile)));
                Bitmap bitmap = ThumbnailUtils.extractThumbnail(sourceBitmap, this.width, this.height, OPTIONS_RECYCLE_INPUT);

                if (bitmap == null) return null;

                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, this.quality, bitmapStream);

//        final FileOutputStream fs = new FileOutputStream(thumbPath);
//
//        bitmapStream.writeTo(fs);

//        ThreadPoolExecutor executor = threadPoolExecutorWeakReference.get();
//
//        executor.execute(new Runnable() {
//          @Override
//          public void run() {
//            try {
//              fs.flush();
//              fs.close();
//            } catch (IOException e) {
//              e.printStackTrace();
//            }
//          }
//        });


                byteArray = bitmapStream.toByteArray();
                bitmap.recycle();
                bitmapStream.close();

            } catch (IOException e) {
                e.printStackTrace();
                return null;
            }


//      final ByteBuffer buffer;
//      if (byteArray != null) {
//        buffer = ByteBuffer.allocateDirect(byteArray.length);
//        buffer.put(byteArray);
//        return buffer;
//      }
            return byteArray;
        }

        @Override
        protected void onPostExecute(byte[] buffer) {
            super.onPostExecute(buffer);
            if (buffer != null) {
                this.pendingResult.success(buffer);
//        this.messenger.send("multi_image_picker/image/" + this.identifier + ".thumb", buffer);
//        buffer.clear();
            } else {
                this.pendingResult.error("-5", "读取文件错误", null);
            }
        }
    }

    /**
     * Gets the content:// URI from the given corresponding path to a file
     *
     * @param context
     * @param filePath
     * @return content Uri
     */
    public static Uri getImageContentUri(Context context, String filePath) {

        Cursor cursor = context.getContentResolver().query(MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                new String[]{MediaStore.Images.Media._ID}, MediaStore.Images.Media.DATA + "=? ",
                new String[]{filePath}, null);
        if (cursor != null && cursor.moveToFirst()) {
            int id = cursor.getInt(cursor.getColumnIndex(MediaStore.MediaColumns._ID));
            Uri baseUri = Uri.parse("content://media/external/images/media");
            return Uri.withAppendedPath(baseUri, "" + id);
        } else {
            ContentValues values = new ContentValues();
            values.put(MediaStore.Images.Media.DATA, filePath);
            return context.getContentResolver().insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
        }
    }

    private static int getOrientation(Context context, String photoPath) {

        int result = 0;


        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            try {
                Uri uri = getImageContentUri(context, photoPath);
                Cursor cursor = context.getContentResolver().query(uri,
                        new String[]{MediaStore.Images.ImageColumns.ORIENTATION}, null, null, null);

                if (cursor == null || cursor.getCount() != 1) {
                    return -1;
                }

                cursor.moveToFirst();
                result = cursor.getInt(0);

            } catch (Exception ignored) {
                result = -1;
            }
        } else {
            try {
                ExifInterface exif = new ExifInterface(photoPath);
                int orientation = exif.getAttributeInt(
                        ExifInterface.TAG_ORIENTATION,
                        ExifInterface.ORIENTATION_NORMAL);

                switch (orientation) {
                    case ExifInterface.ORIENTATION_ROTATE_90:
                        result = 90;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_180:
                        result = 180;
                        break;
                    case ExifInterface.ORIENTATION_ROTATE_270:
                        result = 270;
                        break;
                }
            } catch (Exception ignore) {
                return -1;
            }
        }
        return result;
    }

    private static Bitmap getCorrectlyOrientedImage(Context context, String photoPath) throws IOException {
        Uri photoUri = Uri.fromFile(new File(photoPath));

        InputStream is = context.getContentResolver().openInputStream(photoUri);

        BitmapFactory.Options dbo = new BitmapFactory.Options();
        dbo.inScaled = false;
        dbo.inSampleSize = 1;
        dbo.inJustDecodeBounds = true;
        BitmapFactory.decodeStream(is, null, dbo);
        if (is != null) {
            is.close();
        }

        int orientation = getOrientation(context, photoPath);

        Bitmap srcBitmap;
        is = context.getContentResolver().openInputStream(photoUri);
        srcBitmap = BitmapFactory.decodeStream(is);
        if (is != null) {
            is.close();
        }

        if (orientation > 0) {
            Matrix matrix = new Matrix();
            matrix.postRotate(orientation);

            Bitmap temp = Bitmap.createBitmap(srcBitmap, 0, 0, srcBitmap.getWidth(),
                    srcBitmap.getHeight(), matrix, true);
            srcBitmap.recycle();
            srcBitmap = temp;
//          srcBitmap = Bitmap.createBitmap(srcBitmap, 0, 0, srcBitmap.getWidth(),
//                  srcBitmap.getHeight(), matrix, true);
        }

        return srcBitmap;
    }

    private static String getLastPathSegment(String content) {
        if (content == null || content.length() == 0) {
            return "";
        }
        String[] segments = content.split("/");
        if (segments.length > 0) {
            return segments[segments.length - 1];
        }
        return "";
    }

    private void getAssetsFromCatalog() {

        MethodCall call = this.methodCall;
        MethodChannel.Result result = this.pendingResult;


        if(call == null || result == null)
        {
            Map requestInfo = (Map)permissionRequest.get(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_COLLECTION));
            if(requestInfo == null)
            {
                return;
            }

            call = (MethodCall)requestInfo.get("call");
            result = (MethodChannel.Result)requestInfo.get("result");

        }

        Uri uri = MediaStore.Files.getContentUri("external");

        Map arguments = (Map) call.arguments;

        final String sortOrder = MediaStore.Files.FileColumns.DATE_MODIFIED + " DESC";

        int type = (int) arguments.get("type");

        final String selection =
                MediaStore.Files.FileColumns.MEDIA_TYPE + "=?";

        final String[] selectionArgs = {
                String.valueOf(type == 0 ? MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE : MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO),
        };

        String[] projections = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            projections = new String[]{MediaStore.Files.FileColumns._ID, MediaStore.MediaColumns.DATA,
                    MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATE_MODIFIED,
                    MediaStore.MediaColumns.MIME_TYPE, MediaStore.MediaColumns.WIDTH, MediaStore
                    .MediaColumns.HEIGHT, MediaStore.MediaColumns.SIZE, MediaStore.Images.ImageColumns.ORIENTATION};

        } else {
            projections = new String[]{MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA,
                    MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATE_MODIFIED,
                    MediaStore.MediaColumns.MIME_TYPE, MediaStore.MediaColumns.SIZE, MediaStore.Images.ImageColumns.ORIENTATION};
        }


        // 获取ContentResolver
        ContentResolver contentResolver = context.getContentResolver();
        Cursor cursor = contentResolver.query(uri, projections, selection, selectionArgs, sortOrder);


        ArrayList allChildren = new ArrayList<Map<String, Object>>();

        if (cursor != null && cursor.moveToFirst()) {

//      int idCol = cursor.getColumnIndex(MediaStore.Files.FileColumns._ID);
            int mimeType = cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE);
            int pathCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATA);
            int orientationCol = cursor.getColumnIndex(MediaStore.Images.ImageColumns.ORIENTATION);
//      int sizeCol = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE);
            int WidthCol = 0;
            int HeightCol = 0;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN) {
                WidthCol = cursor.getColumnIndex(MediaStore.MediaColumns.WIDTH);
                HeightCol = cursor.getColumnIndex(MediaStore.MediaColumns.HEIGHT);
            }

            do {

                final String path = cursor.getString(pathCol);

                String folderPath = new File(path).getParentFile().getAbsolutePath();
                String albumName = getLastPathSegment(folderPath);
                if(albumName.equals("picture"))
                {
                    continue;
                }

                int width = 0;
                int height = 0;

                String mintType = cursor.getString(mimeType);

                if (TextUtils.isEmpty(path) || TextUtils.isEmpty(mintType)) {

                    continue;
                }

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN) {
                    width = cursor.getInt(WidthCol);
                    height = cursor.getInt(HeightCol);
                }

                File file = new File(path);
                if (!file.exists() || !file.isFile()) {
                    continue;
                }

                int orientation = cursor.getInt(orientationCol);
                if (orientation == 90 || orientation == 270) {
                    int temp = width;
                    width = height;
                    height = temp;
                }


                Map<String, Object> photoInfo = new HashMap();
                photoInfo.put("identifier", path);
                photoInfo.put("width", width);
                photoInfo.put("height", height);

                allChildren.add(photoInfo);

            } while (cursor.moveToNext());

            cursor.close();
        }

        permissionRequest.remove(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_COLLECTION));

        result.success(allChildren);
        clearMethodCallAndResult();
    }

    private void getAllAssetCatalog() {

        MethodCall call = this.methodCall;
        MethodChannel.Result result = this.pendingResult;


        if(call == null || result == null)
        {
            Map requestInfo = (Map)permissionRequest.get(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_ALL));
            if(requestInfo == null)
            {
                return;
            }

            call = (MethodCall)requestInfo.get("call");
            result = (MethodChannel.Result)requestInfo.get("result");

        }

        Uri uri = MediaStore.Files.getContentUri("external");

        Map arguments = (Map) call.arguments;

        final String sortOrder = MediaStore.Files.FileColumns.DATE_MODIFIED + " DESC";

        int type = (int) arguments.get("type");

        final String selection =
                MediaStore.Files.FileColumns.MEDIA_TYPE + "=?";

        final String[] selectionArgs = {
                String.valueOf(type == 0 ? MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE : MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO),
        };

        String[] projections = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            projections = new String[]{MediaStore.Files.FileColumns._ID, MediaStore.MediaColumns.DATA,
                    MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATE_MODIFIED,
                    MediaStore.MediaColumns.MIME_TYPE, MediaStore.MediaColumns.WIDTH, MediaStore
                    .MediaColumns.HEIGHT, MediaStore.MediaColumns.SIZE, MediaStore.Images.ImageColumns.ORIENTATION};

        } else {
            projections = new String[]{MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DATA,
                    MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATE_MODIFIED,
                    MediaStore.MediaColumns.MIME_TYPE, MediaStore.MediaColumns.SIZE, MediaStore.Images.ImageColumns.ORIENTATION};
        }


        // 获取ContentResolver
        ContentResolver contentResolver = context.getContentResolver();
        Cursor cursor = contentResolver.query(uri, projections, selection, selectionArgs, sortOrder);


        String albumItem_all_name = type == 0 ? "全部照片" : "全部视频";

        Map<String, Map> collectionAlbum = new LinkedHashMap<>();
        Map allMap = new HashMap<String, Object>();
        ArrayList allChildren = new ArrayList<Map<String, Object>>();
        allMap.put("identifier", "all_identifier");
        allMap.put("name", albumItem_all_name);

        allMap.put("children", allChildren);

        collectionAlbum.put(albumItem_all_name, allMap);

        if (cursor != null && cursor.moveToFirst()) {

//      int idCol = cursor.getColumnIndex(MediaStore.Files.FileColumns._ID);
            int mimeType = cursor.getColumnIndex(MediaStore.MediaColumns.MIME_TYPE);
            int pathCol = cursor.getColumnIndex(MediaStore.MediaColumns.DATA);
            int sizeCol = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE);
            int orientationCol = cursor.getColumnIndex(MediaStore.Images.ImageColumns.ORIENTATION);
            int WidthCol = 0;
            int HeightCol = 0;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN) {
                WidthCol = cursor.getColumnIndex(MediaStore.MediaColumns.WIDTH);
                HeightCol = cursor.getColumnIndex(MediaStore.MediaColumns.HEIGHT);
            }

            do {

                final String path = cursor.getString(pathCol);

                int width = 0;
                int height = 0;


                String mintType = cursor.getString(mimeType);

                if (TextUtils.isEmpty(path) || TextUtils.isEmpty(mintType)) {

                    continue;
                }

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN) {
                    width = cursor.getInt(WidthCol);
                    height = cursor.getInt(HeightCol);
                }


                File file = new File(path);
                if (!file.exists() || !file.isFile()) {
                    continue;
                }


                int orientation = cursor.getInt(orientationCol);
                if (orientation == 90 || orientation == 270) {
                    int temp = width;
                    width = height;
                    height = temp;
                }

                // 添加当前图片的专辑到专辑模型实体中
                String folderPath = new File(path).getParentFile().getAbsolutePath();
                String albumName = getLastPathSegment(folderPath);

//        if(width == 0 || height == 0)
//        {
//          Log.d("xx","albu:" + albumName + " mintType："+ mintType);
//        }

                Map<String, Object> photoInfo = new HashMap();
                photoInfo.put("identifier", path);
                photoInfo.put("width", width);
                photoInfo.put("height", height);

                allChildren.add(photoInfo);

                if (allMap.get("last") == null) {
                    allMap.put("last", photoInfo);
                }

                Map album = (Map) collectionAlbum.get(albumName);
                if (album == null) {
                    ArrayList children = new ArrayList<Map<String, Object>>();
                    album = new HashMap<String, Object>();
                    album.put("last", photoInfo);
                    album.put("identifier", folderPath);
                    album.put("name", albumName);
                    children.add(photoInfo);
                    album.put("children", children);

                    collectionAlbum.put(albumName, album);
                } else {
                    ArrayList children = (ArrayList) album.get("children");
                    children.add(photoInfo);
                }

            } while (cursor.moveToNext());

            cursor.close();
        }

        ArrayList arrayList = new ArrayList();

        arrayList.addAll(collectionAlbum.values());

        result.success(arrayList);
        permissionRequest.remove(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_ALL));
        clearMethodCallAndResult();
    }

    private static class GetOriginalImageTask extends AsyncTask<String, Void, byte[]> {
        private final WeakReference<Activity> activityReference;

        final MethodChannel.Result pendingResult;
        final String identifier;
        final int quality;

        GetOriginalImageTask(Activity context, MethodChannel.Result pendingResult, String identifier, int quality) {
            super();
            this.identifier = identifier;
            this.quality = quality;
            this.pendingResult = pendingResult;
            this.activityReference = new WeakReference<>(context);
        }

        @Override
        protected byte[] doInBackground(String... strings) {
//            final Uri uri = Uri.parse(this.identifier);
            byte[] bytesArray = null;

            try {
                // get a reference to the activity if it is still there
                Activity activity = activityReference.get();
                if (activity == null || activity.isFinishing()) return null;

                Bitmap bitmap = getCorrectlyOrientedImage(activity, this.identifier);


                if (bitmap == null) return null;

                ByteArrayOutputStream bitmapStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, this.quality, bitmapStream);
                bytesArray = bitmapStream.toByteArray();
                bitmap.recycle();
                bitmapStream.close();
            } catch (IOException e) {
                e.printStackTrace();
            }

//            assert bytesArray != null;
//            final ByteBuffer buffer = ByteBuffer.allocateDirect(bytesArray.length);
//            buffer.put(bytesArray);
            return bytesArray;
        }

        @Override
        protected void onPostExecute(byte[] buffer) {
            super.onPostExecute(buffer);
            if (buffer != null) {
                this.pendingResult.success(buffer);
//        this.messenger.send("multi_image_picker/image/" + this.identifier + ".thumb", buffer);
//        buffer.clear();
            } else {
                this.pendingResult.error("-5", "读取文件错误", null);
            }
        }
    }

    private boolean requestPermission(int requestCode) {

        if (ContextCompat.checkSelfPermission(this.activity, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
                ||
                ContextCompat.checkSelfPermission(this.activity, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED)
        {
            if(permissionRequest.isEmpty()) {
                Map<String,Object> requestInfo = new HashMap<>();
                requestInfo.put("call",this.methodCall);
                requestInfo.put("result",this.pendingResult);
                permissionRequest.put(String.valueOf(requestCode),requestInfo);
                ActivityCompat.requestPermissions(this.activity,
                        new String[]{
                                Manifest.permission.READ_EXTERNAL_STORAGE,
                                Manifest.permission.WRITE_EXTERNAL_STORAGE
                        },
                        requestCode);
            }
            else
            {
                Map<String,Object> requestInfo = new HashMap<>();
                requestInfo.put("call",this.methodCall);
                requestInfo.put("result",this.pendingResult);
                permissionRequest.put(String.valueOf(requestCode),requestInfo);
            }
            clearMethodCallAndResult();
            return false;

        }

        return true;

    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

        if (permissionRequest.isEmpty()) {
            return false;
        }

        if (permissions.length == 2) {
            if (grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                    grantResults[1] == PackageManager.PERMISSION_GRANTED)
            {
                if(permissionRequest.get(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_ALL)) != null) {
                    getAllAssetCatalog();
                }
                if(permissionRequest.get(String.valueOf(REQUEST_CODE_GRANT_PERMISSIONS_ASSET_COLLECTION)) != null) {
                    getAssetsFromCatalog();
                }
            } else {
                for(Object value : permissionRequest.values()){
                    Map requestInfo = (Map) value;
                    MethodChannel.Result result = (MethodChannel.Result)requestInfo.get("result");
                    result.error("-1000", "用户拒绝访问相册!", null);
                }

                permissionRequest.clear();
                clearMethodCallAndResult();
                return false;
            }

            return true;
        }

        for(Object value : permissionRequest.values()){
            Map requestInfo = (Map) value;
            MethodChannel.Result result = (MethodChannel.Result)requestInfo.get("result");
            result.error("-1000", "用户拒绝访问相册!", null);
        }
        permissionRequest.clear();
        clearMethodCallAndResult();

        return false;
    }

    private void finishWithError(String errorCode, String errorMessage) {
        if (pendingResult != null)
            pendingResult.error(errorCode, errorMessage, null);
        clearMethodCallAndResult();
    }

    private void clearMethodCallAndResult() {
        this.methodCall = null;
        this.pendingResult = null;
    }

}
