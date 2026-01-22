import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/media_item.dart';
import '../../providers/album_provider.dart';

/// 时光详情页面 - 按照 demo2.html 设计
class MomentDetailScreen extends ConsumerStatefulWidget {
  final int mediaId;

  const MomentDetailScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final albumAsync = ref.watch(albumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: albumAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => _buildError('加载失败'),
        data: (items) {
          final item = items.where((i) => i.id == widget.mediaId).firstOrNull;
          if (item == null) {
            return _buildError('照片不存在');
          }
          return _buildContent(context, item);
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MediaItem item) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(item.takenDateTime);

    return Stack(
      children: [
        // 背景点点图案
        const _DoodleBackground(),
        // 主内容
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 60), // 顶部按钮空间
                // 照片卡片
                _buildPhotoCard(context, item),
                const SizedBox(height: 32),
                // 信息卡片
                _buildInfoCard(context, item, dateStr),
              ],
            ),
          ),
        ),
        // 顶部按钮
        _buildTopButtons(context),
      ],
    );
  }

  Widget _buildTopButtons(BuildContext context) {
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
              // 返回按钮 - pets 图标样式
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
                    boxShadow: AppColors.cuteShadow,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pets_rounded,
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
                      size: 24,
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

  Widget _buildPhotoCard(BuildContext context, MediaItem item) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Washi Tape 装饰（顶部）
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.rotate(
              angle: 0.02, // 约 1 度
              child: Container(
                width: 128,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomPaint(
                  painter: _WashiTapePainter(),
                ),
              ),
            ),
          ),
        ),
        // 主卡片
        Transform.rotate(
          angle: 0.035, // 约 2 度
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // 图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPink,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(item.displayPath),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.backgroundPink,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textHint,
                                size: 48,
                              ),
                            ),
                          ),
                          // 内阴影效果
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // 视频播放按钮
                          if (item.isVideo)
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primaryDark,
                                  size: 36,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // LoveSpace 水印
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Transform.rotate(
                      angle: -0.035,
                      child: Text(
                        'LoveSpace',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, MediaItem item, String dateStr) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Speech bubble 小三角
        Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              size: const Size(24, 12),
              painter: _SpeechBubbleArrowPainter(),
            ),
          ),
        ),
        // 主卡片
        Container(
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
              const SizedBox(height: 12),
              // 标题
              Text(
                item.caption ?? '美好的时光 🌴',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // 描述
              Text(
                '只要和你在一起，每一刻都是风景。',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // 分隔线
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
                    onTap: () => _showEditDialog(context, item),
                  ),
                  const SizedBox(width: 24),
                  // 删除按钮
                  _buildActionButton(
                    icon: Icons.delete_rounded,
                    label: '删除',
                    color: AppColors.primary,
                    onTap: () => _showDeleteDialog(context, item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
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

  void _showEditDialog(BuildContext context, MediaItem item) {
    final controller = TextEditingController(text: item.caption ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('编辑标题'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '输入标题...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newCaption = controller.text.trim();
              await ref.read(albumProvider.notifier).updateCaption(
                    item.id!,
                    newCaption.isEmpty ? '' : newCaption,
                  );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('删除照片'),
        content: const Text('确定要删除这张照片吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(albumProvider.notifier).deleteItem(item);
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 背景点点图案
class _DoodleBackground extends StatelessWidget {
  const _DoodleBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DoodlePainter(),
      ),
    );
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

/// Washi Tape 装饰绘制器
class _WashiTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const stripeWidth = 10.0;
    var x = -stripeWidth;

    while (x < size.width + stripeWidth) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
      x += stripeWidth * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Speech Bubble 小三角绘制器
class _SpeechBubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.backgroundWhite
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
