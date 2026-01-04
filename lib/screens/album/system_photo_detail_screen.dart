import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/app_colors.dart';
import '../../services/system_album_service.dart';

/// 系统相册照片详情页面
class SystemPhotoDetailScreen extends ConsumerStatefulWidget {
  final String assetId;

  const SystemPhotoDetailScreen({super.key, required this.assetId});

  @override
  ConsumerState<SystemPhotoDetailScreen> createState() => _SystemPhotoDetailScreenState();
}

class _SystemPhotoDetailScreenState extends ConsumerState<SystemPhotoDetailScreen> {
  AssetEntity? _asset;
  File? _file;
  bool _isLoading = true;
  String? _error;

  // 视频播放器
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;

  // Live Photo 播放器
  VideoPlayerController? _livePhotoController;
  bool _livePhotoInitialized = false;
  bool _isPlayingLivePhoto = false;

  final _service = SystemAlbumService();

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _livePhotoController?.dispose();
    super.dispose();
  }

  Future<void> _loadAsset() async {
    try {
      // 通过 ID 获取 AssetEntity
      final asset = await AssetEntity.fromId(widget.assetId);
      if (asset == null) {
        setState(() {
          _error = '照片不存在';
          _isLoading = false;
        });
        return;
      }

      _asset = asset;

      if (asset.type == AssetType.video) {
        // 视频：获取文件并初始化播放器
        final file = await asset.file;
        if (file != null) {
          _file = file;
          await _initVideoPlayer(file);
        }
      } else {
        // 图片：获取原图数据
        final file = await asset.originFile;
        if (file != null) {
          _file = file;
        }

        // Live Photo：预加载视频
        if (_service.isLivePhoto(asset)) {
          await _initLivePhotoVideo(asset);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initVideoPlayer(File file) async {
    try {
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('视频初始化失败: $e');
    }
  }

  /// 初始化 Live Photo 视频播放器
  Future<void> _initLivePhotoVideo(AssetEntity asset) async {
    try {
      final videoFile = await _service.getLivePhotoVideo(asset);
      if (videoFile != null) {
        _livePhotoController = VideoPlayerController.file(videoFile);
        await _livePhotoController!.initialize();
        _livePhotoController!.setLooping(true);
        setState(() => _livePhotoInitialized = true);
      }
    } catch (e) {
      debugPrint('Live Photo 视频初始化失败: $e');
    }
  }

  /// 开始播放 Live Photo
  void _startLivePhotoPlayback() {
    if (_livePhotoInitialized && _livePhotoController != null) {
      setState(() => _isPlayingLivePhoto = true);
      _livePhotoController!.seekTo(Duration.zero);
      _livePhotoController!.play();
    }
  }

  /// 停止播放 Live Photo
  void _stopLivePhotoPlayback() {
    if (_livePhotoController != null) {
      _livePhotoController!.pause();
      _livePhotoController!.seekTo(Duration.zero);
      setState(() => _isPlayingLivePhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    if (_asset == null) {
      return const Center(
        child: Text('照片不存在', style: TextStyle(color: Colors.white54)),
      );
    }

    if (_asset!.type == AssetType.video) {
      return _buildVideoPlayer();
    }

    // Live Photo 检查
    if (_service.isLivePhoto(_asset!)) {
      return _buildLivePhoto();
    }

    return _buildImage();
  }

  Widget _buildImage() {
    if (_file == null) {
      return const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          _file!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_videoInitialized || _chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildLivePhoto() {
    if (_file == null) {
      return const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _startLivePhotoPlayback(),
      onLongPressEnd: (_) => _stopLivePhotoPlayback(),
      onLongPressCancel: () => _stopLivePhotoPlayback(),
      child: Stack(
        children: [
          // 静态图片（底层）
          Center(
            child: Image.file(
              _file!,
              fit: BoxFit.contain,
            ),
          ),
          // Live Photo 视频（播放时显示）
          if (_isPlayingLivePhoto && _livePhotoInitialized && _livePhotoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _livePhotoController!.value.aspectRatio,
                child: VideoPlayer(_livePhotoController!),
              ),
            ),
          // Live Photo 标识
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isPlayingLivePhoto ? Colors.white : Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.motion_photos_on_rounded,
                    color: _isPlayingLivePhoto ? Colors.black : Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPlayingLivePhoto ? '实况播放中' : '长按播放实况',
                    style: TextStyle(
                      color: _isPlayingLivePhoto ? Colors.black : Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    if (_asset == null) return;

    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    final createDate = _asset!.createDateTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '照片信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('拍摄时间', dateFormat.format(createDate)),
            _buildInfoRow('尺寸', '${_asset!.width} × ${_asset!.height}'),
            _buildInfoRow('类型', _getTypeLabel()),
            if (_asset!.type == AssetType.video)
              _buildInfoRow('时长', _formatDuration(_asset!.videoDuration)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    if (_asset!.type == AssetType.video) return '视频';
    if (_service.isLivePhoto(_asset!)) return '实况照片';
    return '照片';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
