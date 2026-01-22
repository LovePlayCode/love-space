import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../services/media_service.dart';

/// 媒体选择器页面
class MediaPickerScreen extends ConsumerStatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  ConsumerState<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends ConsumerState<MediaPickerScreen> {
  final MediaService _mediaService = MediaService();
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  List<AssetEntity> _assets = [];
  final Set<AssetEntity> _selectedAssets = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _initAlbums();
  }

  Future<void> _initAlbums() async {
    final hasPermission = await _mediaService.requestPermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
      return;
    }

    setState(() => _hasPermission = true);

    final albums = await _mediaService.getAlbums();
    debugPrint('albums: $albums');
    if (albums.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _albums = albums;
      _currentAlbum = albums.first;
    });

    await _loadAssets();
  }

  Future<void> _loadAssets({bool refresh = false}) async {
    if (_currentAlbum == null) return;

    if (refresh) {
      setState(() {
        _currentPage = 0;
        _assets = [];
        _hasMore = true;
      });
    }

    if (!_hasMore) return;

    final assets = await _mediaService.getAssetsFromAlbum(
      _currentAlbum!,
      page: _currentPage,
      pageSize: _pageSize,
    );

    setState(() {
      _assets.addAll(assets);
      _hasMore = assets.length >= _pageSize;
      _currentPage++;
      _isLoading = false;
    });
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  Future<void> _importSelected() async {
    if (_selectedAssets.isEmpty) return;

    final assets = _selectedAssets.toList();
    debugPrint('selected assets: $assets');
    context.pop(assets); // 返回选中的资源
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: _buildAlbumSelector(),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          if (_selectedAssets.isNotEmpty)
            TextButton(
              onPressed: _importSelected,
              child: Text(
                '导入 (${_selectedAssets.length})',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildAlbumSelector() {
    if (_albums.isEmpty) {
      return const Text('选择照片');
    }

    return GestureDetector(
      onTap: _showAlbumPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _currentAlbum?.name ?? '选择相册',
            style: AppTextStyles.subtitle1,
          ),
          const Icon(Icons.arrow_drop_down_rounded),
        ],
      ),
    );
  }

  void _showAlbumPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AlbumPickerSheet(
        albums: _albums,
        currentAlbum: _currentAlbum,
        onAlbumSelected: (album) {
          Navigator.pop(context);
          setState(() {
            _currentAlbum = album;
            _isLoading = true;
          });
          _loadAssets(refresh: true);
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (!_hasPermission) {
      return _buildPermissionDenied();
    }

    if (_assets.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadAssets();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: _assets.length,
        itemBuilder: (context, index) {
          final asset = _assets[index];
          final isSelected = _selectedAssets.contains(asset);
          final selectionIndex = _selectedAssets.toList().indexOf(asset);

          return _AssetTile(
            asset: asset,
            isSelected: isSelected,
            selectionIndex: selectionIndex,
            isLivePhoto: _mediaService.isLivePhoto(asset),
            onTap: () => _toggleSelection(asset),
          );
        },
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              '需要相册访问权限',
              style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '请在系统设置中允许访问相册',
              style: TextStyle(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => PhotoManager.openSetting(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('打开设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '相册为空',
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// 资源缩略图组件
class _AssetTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectionIndex;
  final bool isLivePhoto;
  final VoidCallback onTap;

  const _AssetTile({
    required this.asset,
    required this.isSelected,
    required this.selectionIndex,
    required this.isLivePhoto,
    required this.onTap,
  });

  @override
  State<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<_AssetTile> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final data = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
      quality: 80,
    );
    if (mounted) {
      setState(() => _thumbnailData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 缩略图（已缓存，不会重复加载）
          _thumbnailData != null
              ? Image.memory(_thumbnailData!, fit: BoxFit.cover)
              : Container(color: AppColors.divider),
          // Live Photo 标识
          if (widget.isLivePhoto)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.motion_photos_on_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 2),
                    Text(
                      '实况',
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          // 视频标识
          if (widget.asset.type == AssetType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(widget.asset.videoDuration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          // 选中状态
          if (widget.isSelected)
            Container(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          // 选中序号
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.isSelected ? AppColors.primary : Colors.black38,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: widget.isSelected
                  ? Center(
                      child: Text(
                        '${widget.selectionIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 相册选择器 Sheet
class _AlbumPickerSheet extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? currentAlbum;
  final Function(AssetPathEntity) onAlbumSelected;

  const _AlbumPickerSheet({
    required this.albums,
    required this.currentAlbum,
    required this.onAlbumSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                const Text('选择相册', style: AppTextStyles.subtitle1),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                final isSelected = album.id == currentAlbum?.id;

                return FutureBuilder<int>(
                  future: album.assetCountAsync,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return ListTile(
                      leading: FutureBuilder<List<AssetEntity>>(
                        future: album.getAssetListRange(start: 0, end: 1),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            return FutureBuilder<Uint8List?>(
                              future: snapshot.data!.first.thumbnailDataWithSize(
                                const ThumbnailSize(60, 60),
                              ),
                              builder: (context, thumbSnapshot) {
                                if (thumbSnapshot.hasData && thumbSnapshot.data != null) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.memory(
                                      thumbSnapshot.data!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }
                                return Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.divider,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              },
                            );
                          }
                          return Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.textHint,
                            ),
                          );
                        },
                      ),
                      title: Text(album.name),
                      subtitle: Text('$count 项'),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: AppColors.primary)
                          : null,
                      onTap: () => onAlbumSelected(album),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
