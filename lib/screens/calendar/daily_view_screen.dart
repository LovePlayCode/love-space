import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../models/daily_log.dart';

/// 日记详情页面 - 只读展示
class DailyViewScreen extends ConsumerStatefulWidget {
  final String dateStr;

  const DailyViewScreen({super.key, required this.dateStr});

  @override
  ConsumerState<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends ConsumerState<DailyViewScreen> {
  List<File> _photos = [];
  bool _isLoadingPhotos = true;
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    final dateParts = widget.dateStr.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    final assets = await ref.read(dateMediaProvider(date).future);
    if (assets.isNotEmpty && mounted) {
      final files = <File>[];
      for (final asset in assets) {
        final file = await asset.file;
        if (file != null) {
          files.add(file);
        }
      }
      if (mounted) {
        setState(() {
          _photos = files;
          _isLoadingPhotos = false;
        });
      }
    } else if (mounted) {
      setState(() => _isLoadingPhotos = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = ref.watch(dateLogProvider(widget.dateStr));
    final dateParts = widget.dateStr.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );
    final dateStr = DateFormat('yyyy年M月d日').format(date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 背景点点图案
          const _DoodleBackground(),
          // 主内容
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // 照片卡片
                  _buildPhotoCard(),
                  const SizedBox(height: 24),
                  // 内容卡片
                  _buildContentCard(log, dateStr),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // 顶部按钮
          _buildTopButtons(),
        ],
      ),
    );
  }

  Widget _buildTopButtons() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: AppColors.cuteChunkyShadow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // 分享按钮
              GestureDetector(
                onTap: () {
                  // TODO: 分享功能
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.ios_share_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Transform.rotate(
      angle: 0.035,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // 照片轮播
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _isLoadingPhotos
                    ? Container(
                        color: AppColors.backgroundPink,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _photos.isNotEmpty
                    ? Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: _photos.length,
                            onPageChanged: (index) {
                              setState(() => _currentPhotoIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return Image.file(
                                _photos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    _buildPlaceholder(),
                              );
                            },
                          ),
                          // 指示器
                          if (_photos.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _photos.length,
                                  (index) => Container(
                                    width: index == _currentPhotoIndex ? 16 : 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index == _currentPhotoIndex
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: 8),
            // LoveSpace 水印
            Transform.rotate(
              angle: -0.035,
              child: Text(
                'LoveSpace',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final log = ref.watch(dateLogProvider(widget.dateStr));
    final colors = _getMoodColors(log?.mood);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: log?.hasMood == true
            ? Text(log!.mood!, style: const TextStyle(fontSize: 64))
            : Icon(
                Icons.photo_rounded,
                size: 64,
                color: Colors.white.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildContentCard(DailyLog? log, String dateStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: AppColors.cuteShadow,
      ),
      child: Column(
        children: [
          // 日期标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 标题
          if (log?.hasTitle == true || log?.hasMood == true)
            Text(
              '${log?.mood ?? ''} ${log?.title ?? ''}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            )
          else
            const Text(
              '这一天的记录',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12),
          // 内容
          if (log?.hasContent == true)
            Text(
              log!.content!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          // 分割线
          Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 编辑按钮
              _buildActionButton(
                icon: Icons.edit_rounded,
                label: '编辑',
                color: AppColors.accent,
                onTap: () {
                  context.push('/calendar/day/${widget.dateStr}/edit');
                },
              ),
              const SizedBox(width: 32),
              // 删除按钮
              _buildActionButton(
                icon: Icons.delete_rounded,
                label: '删除',
                color: AppColors.primary,
                onTap: () => _showDeleteDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Icon(icon, color: color, size: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '删除日记',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          '确定要删除这篇日记吗？此操作无法撤销。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(dailyLogProvider.notifier)
                  .deleteLog(widget.dateStr);
              if (mounted) {
                context.pop();
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getMoodColors(String? mood) {
    switch (mood) {
      case '🥰':
        return [const Color(0xFFFFB6C1), const Color(0xFFFF69B4)];
      case '😍':
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
      case '😐':
        return [const Color(0xFFB0C4DE), const Color(0xFF87CEEB)];
      case '😢':
        return [const Color(0xFF6B8E9F), const Color(0xFF4A6572)];
      case '😡':
        return [const Color(0xFFCD5C5C), const Color(0xFF8B0000)];
      default:
        return [AppColors.primaryLighter, AppColors.primary];
    }
  }
}

/// 背景点点图案
class _DoodleBackground extends StatelessWidget {
  const _DoodleBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: CustomPaint(painter: _DoodlePainter()));
  }
}

class _DoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
