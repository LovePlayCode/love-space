import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../providers/couple_provider.dart';
import '../../providers/album_provider.dart';
import '../../models/media_item.dart';
import '../../widgets/common/loading_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 时光/日历 切换状态
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleProvider);
    final albumAsync = ref.watch(albumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: coupleAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: '加载失败',
          onRetry: () => ref.refresh(coupleProvider),
        ),
        data: (coupleInfo) => Stack(
          children: [
            // 背景点点图案
            const _DoodleBackground(),
            // 主内容
            CustomScrollView(
              slivers: [
                // 顶部 Hero 区域
                SliverToBoxAdapter(
                  child: _buildHeroSection(context, ref, coupleInfo),
                ),
                // 时光/日历 切换条
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabDelegate(
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      if (index == 1) {
                        context.go(AppRoutes.calendar);
                      } else {
                        setState(() => _selectedTab = index);
                      }
                    },
                  ),
                ),
                // 最近照片瀑布流
                SliverToBoxAdapter(
                  child: _buildPhotoGrid(context, albumAsync),
                ),
                // 底部间距
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            // 浮动按钮
            Positioned(
              bottom: 100,
              right: 20,
              child: _buildFloatingButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 实现宠物/AI 功能
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.pets_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, WidgetRef ref, coupleInfo) {
    // 获取第一张照片作为背景
    final albumAsync = ref.watch(albumProvider);
    final backgroundImage = albumAsync.maybeWhen(
      data: (items) => items.isNotEmpty ? items.first.displayPath : null,
      orElse: () => null,
    );

    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: AppColors.cuteShadow,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Stack(
          children: [
            // 背景图片（模糊）
            if (backgroundImage != null)
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.1),
                      BlendMode.lighten,
                    ),
                    child: Image.file(
                      File(backgroundImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            // 渐变叠加层 - from-primary/30 via-primary-dark/10 to-white/60
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primaryDark.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            // 底部渐变 - from-black/40 to-transparent
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // 内容
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      // 顶部操作栏
                      _buildTopBar(context),
                      const Spacer(),
                      // 恋爱天数
                      _buildDaysCounter(context, coupleInfo),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo - 带模糊背景
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Colors.red.shade400,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '恋爱空间',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 设置按钮
        GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const Center(
                  child: Icon(
                    Icons.settings_rounded,
                    color: AppColors.textWhite,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysCounter(BuildContext context, coupleInfo) {
    final startDate = coupleInfo.startDate;
    final dateStr = startDate != null
        ? DateFormat('yyyy年MM月dd日').format(startDate)
        : '点击设置开始日期';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 开始日期标签
        GestureDetector(
          onTap: () => context.push(AppRoutes.profileEdit),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '始于 $dateStr',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 在一起 文字
        Text(
          '在一起',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textWhite,
            height: 1.2,
            shadows: [
              Shadow(
                color: AppColors.primaryDark.withValues(alpha: 0.4),
                blurRadius: 0,
                offset: const Offset(2, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 天数显示
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 天数数字卡片
            Transform.rotate(
              angle: -0.035,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  coupleInfo.daysTogetherText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    height: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 天 文字
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '天',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    AsyncValue<List<MediaItem>> albumAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: albumAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, st) => _buildEmptyCard(
          icon: Icons.photo_library_rounded,
          title: '加载失败',
          subtitle: '点击重试',
          onTap: () => context.go(AppRoutes.album),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyCard(
              icon: Icons.photo_library_rounded,
              title: '暂无照片',
              subtitle: '点击添加你们的美好回忆',
              onTap: () => context.go(AppRoutes.album),
            );
          }
          return _buildMasonryGrid(context, items);
        },
      ),
    );
  }

  Widget _buildMasonryGrid(BuildContext context, List<MediaItem> items) {
    // 使用瀑布流布局，模拟 HTML 中的 columns-2 效果
    final List<Widget> leftColumn = [];
    final List<Widget> rightColumn = [];

    // 预设不同的宽高比，与 HTML 中一致
    final ratios = [3 / 4, 1.0, 4 / 3, 3 / 5, 1.0, 2 / 3];

    for (var i = 0; i < items.length && i < 10; i++) {
      final item = items[i];
      final ratio = ratios[i % ratios.length];
      final card = _buildPhotoCard(context, item, ratio);

      if (i % 2 == 0) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: leftColumn),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(children: rightColumn),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(BuildContext context, MediaItem item, double aspectRatio) {
    final dateStr = DateFormat('M月dd日').format(item.takenDateTime);

    return GestureDetector(
      onTap: () => context.push('/moment/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.backgroundWhite,
            width: 2,
          ),
          boxShadow: AppColors.cuteShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片区域
              Container(
                margin: const EdgeInsets.all(10),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 图片
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundPink,
                          ),
                          child: Image.file(
                            File(item.displayPath),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: AppColors.backgroundPink,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textHint,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        // 视频播放按钮
                        if (item.isVideo)
                          Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.primaryDark,
                                size: 28,
                              ),
                            ),
                          ),
                        // 日期标签
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 标题
              if (item.caption != null && item.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: Text(
                    item.caption!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.symmetric(vertical: 48),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: AppColors.cuteShadow,
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
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

    // 错位点
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 粘性 Tab 切换条
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  _StickyTabDelegate({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      color: AppColors.background,
      child: Container(
        height: 56,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: AppColors.cuteChunkyShadow,
        ),
        child: Row(
          children: [
            // 时光按钮
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(0),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedTab == 0 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      '时光',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: selectedTab == 0
                            ? AppColors.textWhite
                            : AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 日历按钮
            Expanded(
              child: GestureDetector(
                onTap: () => onTabChanged(1),
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedTab == 1 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      '日历',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                        color: selectedTab == 1
                            ? AppColors.textWhite
                            : AppColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant _StickyTabDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab;
  }
}
