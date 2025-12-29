import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/theme/app_colors.dart';
import '../../models/media_item.dart';
import '../../providers/album_provider.dart';
import '../../services/database_service.dart';

class PhotoDetailScreen extends ConsumerStatefulWidget {
  final String photoId;

  const PhotoDetailScreen({super.key, required this.photoId});

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  MediaItem? _mediaItem;
  bool _isLoading = true;
  final _captionController = TextEditingController();
  bool _isEditing = false;
  
  // 视频播放器
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _loadMediaItem();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMediaItem() async {
    final id = int.tryParse(widget.photoId);
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final dbService = DatabaseService();
    final item = await dbService.getMediaItemById(id);
    setState(() {
      _mediaItem = item;
      _captionController.text = item?.caption ?? '';
      _isLoading = false;
    });
    
    // 如果是视频，初始化播放器
    if (item != null && item.isVideo) {
      _initVideoPlayer();
    }
  }
  
  Future<void> _initVideoPlayer() async {
    if (_mediaItem == null || !_mediaItem!.isVideo) return;
    
    final file = File(_mediaItem!.localPath);
    debugPrint('[Video] 视频路径: ${_mediaItem!.localPath}');
    debugPrint('[Video] 文件是否存在: ${file.existsSync()}');
    
    if (!file.existsSync()) {
      setState(() {
        _videoError = '视频文件不存在';
        _videoInitialized = true;
      });
      return;
    }
    
    // 获取文件大小用于调试
    final fileSize = await file.length();
    debugPrint('[Video] 文件大小: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
    
    _videoController = VideoPlayerController.file(file);
    
    // 添加错误监听
    _videoController!.addListener(_videoListener);
    
    try {
      debugPrint('[Video] 开始初始化播放器...');
      await _videoController!.initialize();
      debugPrint('[Video] 播放器初始化成功');
      debugPrint('[Video] 视频尺寸: ${_videoController!.value.size}');
      debugPrint('[Video] 视频时长: ${_videoController!.value.duration}');
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
      
      setState(() {
        _videoInitialized = true;
      });
    } catch (e) {
      debugPrint('[Video] 播放器初始化失败: $e');
      setState(() {
        _videoError = '视频加载失败: $e';
        _videoInitialized = true;
      });
    }
  }
  
  void _videoListener() {
    if (_videoController != null && _videoController!.value.hasError) {
      debugPrint('[Video] 播放错误: ${_videoController!.value.errorDescription}');
      setState(() {
        _videoError = _videoController!.value.errorDescription ?? '视频播放出错';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mediaItem == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('照片不存在')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showMoreOptions,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.more_vert_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 图片/视频预览
          Center(
            child: _mediaItem!.isVideo
                ? _buildVideoPlayer()
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImage(),
                  ),
          ),
          // 底部信息
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomInfo(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    // 显示错误信息
    if (_videoError != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 64),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _videoError!,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retryVideoLoad,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 显示加载中
    if (!_videoInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                '视频加载中...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    return Chewie(controller: _chewieController!);
  }
  
  Future<void> _retryVideoLoad() async {
    // 清理旧的控制器
    _videoController?.removeListener(_videoListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    
    setState(() {
      _videoController = null;
      _chewieController = null;
      _videoInitialized = false;
      _videoError = null;
    });
    
    // 重新初始化
    await _initVideoPlayer();
  }

  Widget _buildImage() {
    final file = File(_mediaItem!.localPath);
    if (!file.existsSync()) {
      return Container(
        color: AppColors.backgroundPink,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textHint, size: 64),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 日期
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormat('yyyy年MM月dd日 HH:mm').format(_mediaItem!.takenDateTime),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 备注
          if (_isEditing)
            _buildCaptionEditor()
          else
            _buildCaptionDisplay(),
        ],
      ),
    );
  }

  Widget _buildCaptionDisplay() {
    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _mediaItem!.caption?.isNotEmpty == true
                    ? _mediaItem!.caption!
                    : '点击添加备注...',
                style: TextStyle(
                  color: _mediaItem!.caption?.isNotEmpty == true
                      ? Colors.white
                      : Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '添加备注...',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _captionController.text = _mediaItem!.caption ?? '';
                  setState(() => _isEditing = false);
                },
                child: const Text('取消', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveCaption,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveCaption() async {
    final caption = _captionController.text.trim();
    if (_mediaItem!.id != null) {
      await ref.read(albumProvider.notifier).updateCaption(_mediaItem!.id!, caption);
      setState(() {
        _mediaItem = _mediaItem!.copyWith(caption: caption);
        _isEditing = false;
      });
    }
  }

  void _showMoreOptions() {
    final isVideo = _mediaItem?.isVideo ?? false;
    final mediaType = isVideo ? '视频' : '照片';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('删除$mediaType', style: const TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    final isVideo = _mediaItem?.isVideo ?? false;
    final mediaType = isVideo ? '视频' : '照片';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除$mediaType'),
        content: Text('确定要删除这${isVideo ? '个' : '张'}$mediaType吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_mediaItem != null) {
                await ref.read(albumProvider.notifier).deleteItem(_mediaItem!);
                if (mounted) {
                  context.pop();
                }
              }
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
