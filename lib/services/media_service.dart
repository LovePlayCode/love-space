import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../core/constants/app_constants.dart';
import '../models/media_item.dart';
import 'database_service.dart';

/// 媒体服务 - 管理照片和视频的导入、存储
class MediaService {
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _picker = ImagePicker();

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
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$timestamp$extension';
  }

  /// 从相册选择图片
  Future<List<XFile>> pickImages({int maxImages = 9}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return images.take(maxImages).toList();
    } catch (e) {
      debugPrint('Error picking images: $e');
      return [];
    }
  }

  /// 从相册选择单张图片
  Future<XFile?> pickSingleImage() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// 拍照
  Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// 选择视频
  Future<XFile?> pickVideo() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  /// 录制视频
  Future<XFile?> recordVideo() async {
    try {
      return await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      debugPrint('Error recording video: $e');
      return null;
    }
  }

  /// 将文件保存到应用沙盒目录
  Future<String> saveFileToAppDir(
    File originalFile, {
    bool isVideo = false,
  }) async {
    final subDir = isVideo
        ? AppConstants.videoDirectory
        : AppConstants.imageDirectory;
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
      final thumbnailDir = await _getMediaDirectory(AppConstants.thumbnailDirectory);
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

  /// 导入图片并保存到数据库
  Future<MediaItem?> importImage(XFile xFile, {DateTime? takenDate}) async {
    try {
      final originalFile = File(xFile.path);

      // 保存到沙盒目录
      final localPath = await saveFileToAppDir(originalFile);

      // 获取图片尺寸
      final size = await getImageSize(localPath);

      // 使用传入的日期或当前时间
      final date = takenDate ?? DateTime.now();

      // 创建媒体项
      final mediaItem = MediaItem(
        type: AppConstants.mediaTypeImage,
        localPath: localPath,
        takenDate: date.millisecondsSinceEpoch,
        width: size['width'],
        height: size['height'],
      );

      // 保存到数据库
      final id = await _dbService.insertMediaItem(mediaItem);

      return mediaItem.copyWith(id: id);
    } catch (e) {
      debugPrint('Error importing image: $e');
      return null;
    }
  }

  /// 批量导入图片
  Future<List<MediaItem>> importImages(
    List<XFile> xFiles, {
    DateTime? takenDate,
  }) async {
    final List<MediaItem> items = [];
    for (final xFile in xFiles) {
      final item = await importImage(xFile, takenDate: takenDate);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  /// 导入视频并保存到数据库
  Future<MediaItem?> importVideo(XFile xFile, {DateTime? takenDate}) async {
    try {
      final originalFile = File(xFile.path);

      // 保存到沙盒目录
      final localPath = await saveFileToAppDir(originalFile, isVideo: true);

      // 生成视频封面
      final thumbnailPath = await generateVideoThumbnail(localPath);

      // 获取封面尺寸
      Map<String, int>? size;
      if (thumbnailPath != null) {
        size = await getImageSize(thumbnailPath);
      }

      // 使用传入的日期或当前时间
      final date = takenDate ?? DateTime.now();

      // 创建媒体项
      final mediaItem = MediaItem(
        type: AppConstants.mediaTypeVideo,
        localPath: localPath,
        thumbnailPath: thumbnailPath,
        takenDate: date.millisecondsSinceEpoch,
        width: size?['width'],
        height: size?['height'],
      );

      // 保存到数据库
      final id = await _dbService.insertMediaItem(mediaItem);

      return mediaItem.copyWith(id: id);
    } catch (e) {
      debugPrint('Error importing video: $e');
      return null;
    }
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
      // 删除视频文件
      await deleteMediaFile(item.localPath);

      // 删除封面文件
      if (item.thumbnailPath != null) {
        await deleteMediaFile(item.thumbnailPath!);
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
}
