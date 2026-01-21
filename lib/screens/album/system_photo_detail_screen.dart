import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/constants/tag_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tag.dart';
import '../../providers/tag_provider.dart';
import '../../services/database_service.dart';
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
  List<Tag> _assetTags = [];

  // 视频播放器
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;

  // Live Photo 播放器
  VideoPlayerController? _livePhotoController;
  bool _livePhotoInitialized = false;
  bool _isPlayingLivePhoto = false;

  final _service = SystemAlbumService();
  final _dbService = DatabaseService();

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

      // 加载标签
      final tags = await _dbService.getTagsForAsset(widget.assetId);
      _assetTags = tags;

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
            onPressed: _showTagEditSheet,
            icon: const Icon(Icons.label_outline_rounded, color: Colors.white),
          ),
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

  void _showTagEditSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => _AssetTagEditSheet(
          assetId: widget.assetId,
          currentTags: _assetTags,
          scrollController: scrollController,
          onTagsChanged: (tags) {
            setState(() => _assetTags = tags);
          },
        ),
      ),
    );
  }
}

/// 系统相册标签编辑 Sheet
class _AssetTagEditSheet extends ConsumerStatefulWidget {
  final String assetId;
  final List<Tag> currentTags;
  final ScrollController scrollController;
  final Function(List<Tag>) onTagsChanged;

  const _AssetTagEditSheet({
    required this.assetId,
    required this.currentTags,
    required this.scrollController,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<_AssetTagEditSheet> createState() => _AssetTagEditSheetState();
}

class _AssetTagEditSheetState extends ConsumerState<_AssetTagEditSheet> {
  late Set<int> _selectedTagIds;
  final _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTagIds = widget.currentTags.map((t) => t.id!).toSet();
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagProvider);

    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('编辑标签', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showCreateTagDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建'),
                      ),
                      TextButton(
                        onPressed: () => _saveTags(context),
                        child: const Text('完成'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 标签列表
        Expanded(
          child: tagsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('加载失败: $e')),
            data: (tags) {
              if (tags.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.label_off_rounded, size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('还没有标签', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _showCreateTagDialog(context),
                        child: const Text('创建第一个标签'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedTagIds.add(tag.id!);
                        } else {
                          _selectedTagIds.remove(tag.id);
                        }
                      });
                    },
                    title: Text(tag.name),
                    secondary: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getTagColor(tag.color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        TagIcons.getIcon(tag.icon) ?? Icons.label_rounded,
                        color: _getTagColor(tag.color),
                        size: 18,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getTagColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  void _showCreateTagDialog(BuildContext context) {
    _newTagController.clear();
    String? selectedIcon;
    String? selectedColor;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建标签'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _newTagController,
                  decoration: const InputDecoration(
                    hintText: '输入标签名称',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('选择图标', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildIconSelector(
                  selectedIcon: selectedIcon,
                  selectedColor: selectedColor,
                  onIconSelected: (icon) {
                    setDialogState(() => selectedIcon = icon);
                  },
                ),
                const SizedBox(height: 16),
                const Text('选择颜色', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _buildColorSelector(
                  selectedColor: selectedColor,
                  onColorSelected: (color) {
                    setDialogState(() => selectedColor = color);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = _newTagController.text.trim();
                if (name.isNotEmpty) {
                  final newTag = await ref.read(tagProvider.notifier).createTag(
                    name,
                    color: selectedColor,
                    icon: selectedIcon,
                  );
                  if (newTag != null && context.mounted) {
                    setState(() {
                      _selectedTagIds.add(newTag.id!);
                    });
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconSelector({
    String? selectedIcon,
    String? selectedColor,
    required Function(String?) onIconSelected,
  }) {
    final color = _getTagColor(selectedColor);
    final iconCodes = TagIcons.allIconCodes;
    return SizedBox(
      height: 200,
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: iconCodes.map((iconCode) {
            final icon = TagIcons.getIcon(iconCode);
            final isSelected = selectedIcon == iconCode;
            return GestureDetector(
              onTap: () => onIconSelected(iconCode),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: color, width: 2) : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    String? selectedColor,
    required Function(String?) onColorSelected,
  }) {
    const colors = [
      '#FF6B6B', '#FF8E53', '#FFC93C', '#6BCB77', '#4D96FF',
      '#9B59B6', '#E91E63', '#00BCD4', '#795548', '#607D8B',
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorHex) {
        final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        final isSelected = selectedColor == colorHex;
        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveTags(BuildContext context) async {
    final dbService = DatabaseService();
    await dbService.setTagsForAsset(widget.assetId, _selectedTagIds.toList());
    
    // 获取更新后的标签列表
    final updatedTags = await dbService.getTagsForAsset(widget.assetId);
    widget.onTagsChanged(updatedTags);
    
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
