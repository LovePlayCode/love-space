import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_router.dart';
import '../../models/anniversary.dart';
import '../../providers/anniversary_provider.dart';
import '../../widgets/common/loading_widget.dart';

class AnniversaryScreen extends ConsumerWidget {
  const AnniversaryScreen({super.key});

  // 辅助色
  static const Color secondaryGreen = Color(0xFF88D4AB);
  static const Color secondaryYellow = Color(0xFFFFD93D);
  static const Color secondaryBlue = Color(0xFF6BCBFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anniversariesAsync = ref.watch(anniversaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 点点背景
          const _DotBackground(),
          // 主内容
          SafeArea(
            child: anniversariesAsync.when(
              loading: () => const LoadingWidget(),
              error: (error, stack) => AppErrorWidget(
                message: '加载失败',
                onRetry: () => ref.refresh(anniversaryProvider),
              ),
              data: (anniversaries) {
                return CustomScrollView(
                  slivers: [
                    // 顶部导航栏
                    _buildHeader(context),
                    // 内容
                    if (anniversaries.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmptyState(context),
                      )
                    else
                      _buildContent(context, ref, anniversaries),
                    // 底部间距
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                );
              },
            ),
          ),
          // 悬浮添加按钮
          _buildFloatingButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 返回按钮
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
            // 标题
            const Text(
              '纪念日',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: 2,
              ),
            ),
            // 添加按钮
            GestureDetector(
              onTap: () => context.push(AppRoutes.anniversaryAdd),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  '添加',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyWidget(
      icon: Icons.celebration_rounded,
      title: '还没有纪念日',
      subtitle: '添加你们的重要日子，让每一天都值得纪念',
      action: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.anniversaryAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加纪念日'),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Anniversary> anniversaries,
  ) {
    // 分组：即将到来、已过去
    final upcoming = anniversaries.where((a) => a.daysUntil >= 0).toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    final past = anniversaries
        .where((a) => a.daysUntil < 0 && !a.isRecurring)
        .toList()
      ..sort((a, b) => b.daysUntil.compareTo(a.daysUntil));

    // 找到最近的一个纪念日作为顶部大卡片
    final nextBig = upcoming.isNotEmpty ? upcoming.first : null;
    final otherUpcoming = upcoming.length > 1 ? upcoming.sublist(1) : <Anniversary>[];

    return SliverList(
      delegate: SliverChildListDelegate([
        // 顶部大卡片
        if (nextBig != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildHeroCard(context, ref, nextBig),
          ),
        // 即将到来列表
        if (otherUpcoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(
            icon: Icons.star_rounded,
            iconColor: secondaryYellow,
            title: '即将到来',
            titleColor: AppColors.primaryDark,
            badge: '期待中...',
            badgeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          ...otherUpcoming.map(
            (a) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildUpcomingCard(context, ref, a),
            ),
          ),
        ],
        // 美好回忆列表
        if (past.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            icon: Icons.favorite_rounded,
            iconColor: secondaryGreen,
            title: '美好回忆',
            titleColor: secondaryGreen,
            badge: '点点滴滴',
            badgeColor: secondaryGreen,
          ),
          const SizedBox(height: 16),
          ...past.map(
            (a) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPastCard(context, ref, a),
            ),
          ),
        ],
      ]),
    );
  }

  // 顶部大卡片 - 下一个大日子
  Widget _buildHeroCard(BuildContext context, WidgetRef ref, Anniversary anniversary) {
    final dateFormat = DateFormat('yyyy年M月d日');
    final dateStr = dateFormat.format(anniversary.date);

    return GestureDetector(
      onTap: () => _showAnniversaryOptions(context, ref, anniversary),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 0,
                offset: Offset(0, 6),
              ),
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(
              children: [
                // 背景图片
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // 渐变遮罩
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.primaryDark.withValues(alpha: 0.3),
                          AppColors.primaryDark.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                // 内容
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标签
                        Transform.rotate(
                          angle: -0.035,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              '✨ 下一个大日子',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 标题
                        Text(
                          anniversary.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Color(0x40000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 倒计时
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                anniversary.isToday ? '🎉' : '${anniversary.daysUntil}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                anniversary.isToday ? '今天' : '天后',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 日期
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String badge,
    required Color badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 即将到来的卡片
  Widget _buildUpcomingCard(BuildContext context, WidgetRef ref, Anniversary anniversary) {
    final dateFormat = DateFormat('yyyy年M月d日');
    final dateStr = dateFormat.format(anniversary.date);
    final iconColor = _getIconColor(anniversary.type);
    // 计算进度（假设最大 365 天）
    final progress = 1 - (anniversary.daysUntil / 365).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => _showAnniversaryOptions(context, ref, anniversary),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 0,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // 图标
                Transform.rotate(
                  angle: -0.1,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        anniversary.icon ?? '💝',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anniversary.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // 倒计时标签
                Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '还有 ${anniversary.daysUntil} 天',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 进度条
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFF0F0F0),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(6),
                          border: const Border(
                            right: BorderSide(
                              color: Colors.white,
                              width: 2,
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
        ),
      ),
    );
  }

  // 已过去的卡片（美好回忆）
  Widget _buildPastCard(BuildContext context, WidgetRef ref, Anniversary anniversary) {
    final dateFormat = DateFormat('yyyy年M月d日');
    final dateStr = dateFormat.format(anniversary.date);
    final daysPast = -anniversary.daysUntil;
    final displayText = daysPast >= 365
        ? '已过 ${(daysPast / 365).toStringAsFixed(1)} 年'
        : '已过 $daysPast 天';

    return GestureDetector(
      onTap: () => _showAnniversaryOptions(context, ref, anniversary),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FFF4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: secondaryGreen.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    anniversary.icon ?? '💝',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anniversary.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // 已过天数标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: secondaryGreen.withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: secondaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    return Positioned(
      bottom: 96,
      right: 24,
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.anniversaryAdd),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE06868),
                blurRadius: 0,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'travel':
        return secondaryBlue;
      case 'birthday':
      case 'anniversary':
        return AppColors.primary;
      case 'holiday':
        return secondaryYellow;
      default:
        return secondaryBlue;
    }
  }

  void _showAnniversaryOptions(
    BuildContext context,
    WidgetRef ref,
    Anniversary anniversary,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              // 纪念日信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          anniversary.icon ?? '💝',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            anniversary.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            anniversary.eventDate,
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  '编辑',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '${AppRoutes.anniversaryEdit}?id=${anniversary.id}',
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  '删除',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, anniversary);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Anniversary anniversary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          '删除纪念日',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '确定要删除「${anniversary.title}」吗？',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (anniversary.id != null) {
                await ref
                    .read(anniversaryProvider.notifier)
                    .deleteAnniversary(anniversary.id!);
              }
            },
            child: const Text(
              '删除',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 点点背景
class _DotBackground extends StatelessWidget {
  const _DotBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.background,
        child: CustomPaint(
          painter: _DotPainter(),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE4E4)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
