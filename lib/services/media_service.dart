import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../core/constants/app_constants.dart';
import '../models/media_item.dart';
import 'database_service.dart';

/// 媒体服务 - 管理照片和视频的导入、存储（支持 Live Photo）
class MediaService {
  final DatabaseService _dbService = DatabaseService();
  final Random _random = Random();

  /// 获取应用媒体存储目录
  Future<Directory> _getMediaDirectory(String subDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/$subDir');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// 生成唯一文件名
  String _generateFileName(String extension) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(99999).toString().padLeft(5, '0');
    return '${timestamp}_$randomSuffix$extension';
  }

  /// 请求相册权限
  Future<bool> requestPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth || ps.hasAccess;
  }

  /// 获取所有相册
  Future<List<AssetPathEntity>> getAlbums({
    RequestType type = RequestType.common,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    return await PhotoManager.getAssetPathList(
      type: type,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        videoOption: const FilterOption(
          durationConstraint: DurationConstraint(
            max: Duration(minutes: 10),
          ),
        ),
      ),
    );
  }

  /// 获取相册中的资源
  Future<List<AssetEntity>> getAssetsFromAlbum(
    AssetPathEntity album, {
    int page = 0,
    int pageSize = 80,
  }) async {
    return await album.getAssetListPaged(page: page, size: pageSize);
  }

  /// 获取所有资源（最近的）
  Future<List<AssetEntity>> getRecentAssets({
    int count = 100,
    RequestType type = RequestType.common,
  }) async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    final albums = await PhotoManager.getAssetPathList(
      type: type,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    if (albums.isEmpty) return [];

    // 获取"最近项目"相册
    final recentAlbum = albums.first;
    return await recentAlbum.getAssetListPaged(page: 0, size: count);
  }

  /// 检查是否为 Live Photo
  bool isLivePhoto(AssetEntity asset) {
    // 仅 iOS 支持 Live Photo
    if (!Platform.isIOS) return false;
    // 检查是否为图片类型且是 Live Photo
    return asset.type == AssetType.image &&
        (asset.subtype & 8) != 0; // Live Photo 的 subtype 标志位
  }

  /// 获取资源的缩略图
  Future<Uint8List?> getThumbnail(
    AssetEntity asset, {
    int width = 200,
    int height = 200,
  }) async {
    return await asset.thumbnailDataWithSize(
      ThumbnailSize(width, height),
      quality: 80,
    );
  }

  /// 获取 Live Photo 的视频文件
  Future<File?> getLivePhotoVideo(AssetEntity asset) async {
    if (!isLivePhoto(asset)) return null;

    try {
      // 使用 originFileWithSubtype 获取 Live Photo 的视频部分
      final file = await asset.originFileWithSubtype;
      if (file != null && await file.exists()) {
        // 检查是否为视频文件
        final ext = p.extension(file.path).toLowerCase();
        if (ext == '.mov' || ext == '.mp4') {
          return file;
        }
      }

      // 备选方案：尝试直接获取原始文件
      final videoFile = await asset.loadFile(isOrigin: true);
      return videoFile;
    } catch (e) {
      debugPrint('[LivePhoto] 获取视频失败: $e');
      return null;
    }
  }

  /// 将文件保存到应用沙盒目录
  Future<String> saveFileToAppDir(
    File originalFile, {
    bool isVideo = false,
    bool isLivePhotoVideo = false,
  }) async {
    String subDir;
    if (isLivePhotoVideo) {
      subDir = AppConstants.livePhotoDirectory;
    } else if (isVideo) {
      subDir = AppConstants.videoDirectory;
    } else {
      subDir = AppConstants.imageDirectory;
    }

    final mediaDir = await _getMediaDirectory(subDir);
    final extension = p.extension(originalFile.path);
    final fileName = _generateFileName(extension);
    final savedFile = await originalFile.copy('${mediaDir.path}/$fileName');
    return savedFile.path;
  }

  /// 获取图片尺寸
  Future<Map<String, int>> getImageSize(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      return {'width': image.width, 'height': image.height};
    } catch (e) {
      debugPrint('Error getting image size: $e');
      return {'width': 0, 'height': 0};
    }
  }

  /// 生成视频封面（第一帧）
  Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailDir =
          await _getMediaDirectory(AppConstants.thumbnailDirectory);
      final fileName = _generateFileName('.jpg');
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 85,
      );
      if (thumbnailPath != null) {
        // 重命名为我们的文件名格式
        final file = File(thumbnailPath);
        final newPath = '${thumbnailDir.path}/$fileName';
        await file.rename(newPath);
        return newPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// 导入资源（自动识别类型：图片/视频/Live Photo）
  Future<MediaItem?> importAsset(AssetEntity asset) async {
    try {
      final file = await asset.originFile;
      if (file == null || !await file.exists()) {
        debugPrint('[Import] 无法获取原始文件');
        return null;
      }

      final isLive = isLivePhoto(asset);
      final isVideo = asset.type == AssetType.video;

      int mediaType;
      String? liveVideoPath;
      String? thumbnailPath;

      if (isLive) {
        // Live Photo
        mediaType = AppConstants.mediaTypeLivePhoto;

        // 获取并保存 Live Photo 的视频部分
        final videoFile = await getLivePhotoVideo(asset);
        if (videoFile != null) {
          liveVideoPath =
              await saveFileToAppDir(videoFile, isLivePhotoVideo: true);
          debugPrint('[Import] Live Photo 视频已保存: $liveVideoPath');
        }
      } else if (isVideo) {
        // 普通视频
        mediaType = AppConstants.mediaTypeVideo;
      } else {
        // 普通图片
        mediaType = AppConstants.mediaTypeImage;
      }

      // 保存主文件（图片或视频）
      final localPath = await _saveAssetFile(asset, file, isVideo);

      // 视频需要生成封面
      if (isVideo) {
        thumbnailPath = await generateVideoThumbnail(localPath);
      }

      // 获取尺寸
      Map<String, int>? size;
      if (isVideo && thumbnailPath != null) {
        size = await getImageSize(thumbnailPath);
      } else if (!isVideo) {
        size = await getImageSize(localPath);
      }

      // 获取拍摄时间
      final takenDate =
          asset.createDateTime.millisecondsSinceEpoch;

      // 创建媒体项
      final mediaItem = MediaItem(
        type: mediaType,
        localPath: localPath,
        thumbnailPath: thumbnailPath,
        liveVideoPath: liveVideoPath,
        takenDate: takenDate,
        width: size?['width'] ?? asset.width,
        height: size?['height'] ?? asset.height,
      );

      // 保存到数据库
      final id = await _dbService.insertMediaItem(mediaItem);

      return mediaItem.copyWith(id: id);
    } catch (e) {
      debugPrint('[Import] 导入失败: $e');
      return null;
    }
  }

  /// 保存资源文件到应用目录
  Future<String> _saveAssetFile(
    AssetEntity asset,
    File file,
    bool isVideo,
  ) async {
    if (isVideo) {
      return await saveFileToAppDir(file, isVideo: true);
    }

    // 图片需要压缩
    final mediaDir = await _getMediaDirectory(AppConstants.imageDirectory);
    final fileName = _generateFileName('.jpg');
    final targetPath = '${mediaDir.path}/$fileName';

    try {
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 85,
        minWidth: 1920,
        minHeight: 1920,
      );

      if (compressedFile != null) {
        return compressedFile.path;
      }
    } catch (e) {
      debugPrint('[Import] 压缩失败，使用原图: $e');
    }

    // 压缩失败，直接复制
    await file.copy(targetPath);
    return targetPath;
  }

  /// 批量导入资源
  Future<List<MediaItem>> importAssets(
    List<AssetEntity> assets, {
    Function(int completed, int total)? onProgress,
  }) async {
    final List<MediaItem> items = [];
    final total = assets.length;

    for (int i = 0; i < total; i++) {
      final item = await importAsset(assets[i]);
      if (item != null) {
        items.add(item);
      }
      onProgress?.call(i + 1, total);
    }

    return items;
  }

  /// 删除媒体文件
  Future<bool> deleteMediaFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting media file: $e');
      return false;
    }
  }

  /// 删除媒体项（包括文件和数据库记录）
  Future<bool> deleteMediaItem(MediaItem item) async {
    try {
      // 删除主文件
      await deleteMediaFile(item.localPath);

      // 删除封面文件
      if (item.thumbnailPath != null) {
        await deleteMediaFile(item.thumbnailPath!);
      }

      // 删除 Live Photo 视频文件
      if (item.liveVideoPath != null) {
        await deleteMediaFile(item.liveVideoPath!);
      }

      // 删除数据库记录
      if (item.id != null) {
        await _dbService.deleteMediaItem(item.id!);
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting media item: $e');
      return false;
    }
  }

  /// 更新媒体项备注
  Future<bool> updateCaption(int id, String caption) async {
    try {
      final item = await _dbService.getMediaItemById(id);
      if (item != null) {
        final updated = item.copyWith(caption: caption);
        await _dbService.updateMediaItem(updated);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating caption: $e');
      return false;
    }
  }

  /// 获取所有媒体项
  Future<List<MediaItem>> getAllMediaItems() async {
    return await _dbService.getAllMediaItems();
  }

  /// 获取指定日期的媒体项
  Future<List<MediaItem>> getMediaItemsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return await _dbService.getMediaItemsByDateRange(
      startOfDay.millisecondsSinceEpoch,
      endOfDay.millisecondsSinceEpoch,
    );
  }

  /// 获取媒体总数
  Future<int> getMediaCount() async {
    return await _dbService.getMediaCount();
  }

  /// 选择单张图片（用于头像等场景）
  Future<AssetEntity?> pickSingleImage() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isEmpty) return null;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 1);
    return assets.isNotEmpty ? assets.first : null;
  }

  /// 打开系统相机拍照
  Future<AssetEntity?> takePhoto() async {
    // photo_manager 不直接支持拍照，需要使用其他方式
    // 这里返回 null，由 UI 层处理
    return null;
  }

  /// 打开系统相机录像
  Future<AssetEntity?> recordVideo() async {
    // photo_manager 不直接支持录像，需要使用其他方式
    // 这里返回 null，由 UI 层处理
    return null;
  }
}
