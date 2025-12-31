import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';

/// Live Photo 播放器组件
/// 自动播放实况照片的视频部分，支持循环播放
class LivePhotoPlayer extends StatefulWidget {
  /// 静态图片路径
  final String imagePath;

  /// Live Photo 视频路径
  final String videoPath;

  /// 是否自动播放
  final bool autoPlay;

  /// 是否循环播放
  final bool loop;

  /// 是否显示播放控制
  final bool showControls;

  const LivePhotoPlayer({
    super.key,
    required this.imagePath,
    required this.videoPath,
    this.autoPlay = true,
    this.loop = true,
    this.showControls = false,
  });

  @override
  State<LivePhotoPlayer> createState() => _LivePhotoPlayerState();
}

class _LivePhotoPlayerState extends State<LivePhotoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer() async {
    final file = File(widget.videoPath);

    if (!await file.exists()) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    _controller = VideoPlayerController.file(file);
    _controller!.addListener(_videoListener);

    try {
      await _controller!.initialize();
      await _controller!.setLooping(widget.loop);
      await _controller!.setVolume(0); // 静音播放

      setState(() {
        _isInitialized = true;
      });

      if (widget.autoPlay) {
        _play();
      }
    } catch (e) {
      debugPrint('[LivePhotoPlayer] 初始化失败: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    final isPlaying = _controller!.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() => _isPlaying = isPlaying);
    }

    if (_controller!.value.hasError) {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _play() async {
    if (_controller != null && _isInitialized) {
      await _controller!.play();
    }
  }

  Future<void> _pause() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pause();
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _pause();
    } else {
      await _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 底层：静态图片（作为占位和加载失败时的后备）
        _buildStaticImage(),

        // 上层：视频播放器
        if (_isInitialized && !_hasError) _buildVideoPlayer(),

        // Live Photo 标识
        _buildLivePhotoIndicator(),

        // 播放控制（可选）
        if (widget.showControls) _buildControls(),
      ],
    );
  }

  Widget _buildStaticImage() {
    final file = File(widget.imagePath);
    if (!file.existsSync()) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: Colors.white54,
            size: 48,
          ),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) return const SizedBox.shrink();

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildLivePhotoIndicator() {
    return Positioned(
      top: 16,
      left: 16,
      child: AnimatedOpacity(
        opacity: _isPlaying ? 1.0 : 0.7,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPlaying
                    ? Icons.motion_photos_on_rounded
                    : Icons.motion_photos_paused_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isPlaying ? '实况播放中' : '实况',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

/// 简化版 Live Photo 播放器（仅用于预览，不带控制）
class SimpleLivePhotoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;

  const SimpleLivePhotoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = true,
  });

  @override
  State<SimpleLivePhotoPlayer> createState() => _SimpleLivePhotoPlayerState();
}

class _SimpleLivePhotoPlayerState extends State<SimpleLivePhotoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final file = File(widget.videoPath);
    if (!await file.exists()) return;

    _controller = VideoPlayerController.file(file);

    try {
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.setVolume(0);

      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.autoPlay) {
          await _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('[SimpleLivePhotoPlayer] 初始化失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
