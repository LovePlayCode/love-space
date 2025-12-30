import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/constants/tag_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../models/media_item.dart';
import '../../models/tag.dart';
import '../../providers/album_provider.dart';
import '../../providers/tag_provider.dart';
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
  List<Tag> _mediaTags = [];
  
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
    final tags = await dbService.getTagsForMedia(id);
    
    setState(() {
      _mediaItem = item;
      _captionController.text = item?.caption ?? '';
      _mediaTags = tags;
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
          Positioned.fill(
            child: _mediaItem!.isVideo
                ? _buildVideoPlayer()
                : Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildImage(),
                    ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
      );
    }
    
    // 显示加载中
    if (!_videoInitialized || _chewieController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              '视频加载中...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
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
          // 标签
          _buildTagsSection(),
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

  Widget _buildTagsSection() {
    return GestureDetector(
      onTap: () => _showTagEditSheet(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.label_rounded, color: Colors.white54, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: _mediaTags.isEmpty
                  ? const Text(
                      '点击添加标签...',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _mediaTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(tag.color).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _getTagColor(tag.color).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tag.icon != null) ...[
                              Icon(
                                TagIcons.getIcon(tag.icon),
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              tag.name,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
            ),
            const Icon(Icons.edit_rounded, color: Colors.white54, size: 18),
          ],
        ),
      ),
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
        builder: (context, scrollController) => _MediaTagEditSheet(
          mediaId: _mediaItem!.id!,
          currentTags: _mediaTags,
          scrollController: scrollController,
          onTagsChanged: (tags) {
            setState(() => _mediaTags = tags);
          },
        ),
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

/// 媒体标签编辑 Sheet
class _MediaTagEditSheet extends ConsumerStatefulWidget {
  final int mediaId;
  final List<Tag> currentTags;
  final ScrollController scrollController;
  final Function(List<Tag>) onTagsChanged;

  const _MediaTagEditSheet({
    required this.mediaId,
    required this.currentTags,
    required this.scrollController,
    required this.onTagsChanged,
  });

  @override
  ConsumerState<_MediaTagEditSheet> createState() => _MediaTagEditSheetState();
}

class _MediaTagEditSheetState extends ConsumerState<_MediaTagEditSheet> {
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
      '#FF5722', // 深橙
      '#E91E63', // 粉红
      '#9C27B0', // 紫色
      '#673AB7', // 深紫
      '#3F51B5', // 靛蓝
      '#2196F3', // 蓝色
      '#00BCD4', // 青色
      '#009688', // 蓝绿
      '#4CAF50', // 绿色
      '#8BC34A', // 浅绿
      '#FF9800', // 橙色
      '#795548', // 棕色
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
    await dbService.setTagsForMedia(widget.mediaId, _selectedTagIds.toList());
    
    // 获取更新后的标签列表
    final updatedTags = await dbService.getTagsForMedia(widget.mediaId);
    widget.onTagsChanged(updatedTags);
    
    // 刷新筛选结果
    ref.invalidate(mediaByTagsProvider);
    
    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
