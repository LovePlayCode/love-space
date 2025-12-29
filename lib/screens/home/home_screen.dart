import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/routes/app_router.dart';
import '../../providers/couple_provider.dart';
import '../../providers/anniversary_provider.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(coupleProvider);
    final upcomingAnniversaries = ref.watch(upcomingAnniversariesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: coupleAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: '加载失败',
          onRetry: () => ref.refresh(coupleProvider),
        ),
        data: (coupleInfo) => CustomScrollView(
          slivers: [
            // 顶部区域
            SliverToBoxAdapter(child: _buildHeader(context, ref, coupleInfo)),
            // 功能入口
            SliverToBoxAdapter(child: _buildFeatureGrid(context)),
            // 即将到来的纪念日
            if (upcomingAnniversaries.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildUpcomingAnniversaries(
                  context,
                  upcomingAnniversaries,
                ),
              ),
            // 底部间距
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, coupleInfo) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            children: [
              // 顶部操作栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'LoveSpace',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.settings),
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 情侣头像
              CoupleAvatarWidget(
                myAvatar: coupleInfo.myAvatar,
                partnerAvatar: coupleInfo.partnerAvatar,
                avatarSize: 80,
                onMyAvatarTap: () => context.push(AppRoutes.profileEdit),
                onPartnerAvatarTap: () => context.push(AppRoutes.profileEdit),
              ),
              const SizedBox(height: 16),
              // 昵称
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    coupleInfo.myNickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: AppColors.textWhite,
                      size: 16,
                    ),
                  ),
                  Text(
                    coupleInfo.partnerNickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 恋爱天数
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      '我们在一起',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          coupleInfo.daysTogetherText,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textWhite,
                            height: 1.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            '天',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!coupleInfo.hasStartDate) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.profileEdit),
                        child: const Text(
                          '点击设置恋爱开始日期',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.photo_library_rounded,
        label: '时光相册',
        color: const Color(0xFFFF8FA3),
        onTap: () => context.go(AppRoutes.album),
      ),
      _FeatureItem(
        icon: Icons.calendar_month_rounded,
        label: '爱的日历',
        color: const Color(0xFF6C9BCF),
        onTap: () => context.go(AppRoutes.calendar),
      ),
      _FeatureItem(
        icon: Icons.celebration_rounded,
        label: '纪念日',
        color: const Color(0xFFFFD93D),
        onTap: () => context.go(AppRoutes.anniversary),
      ),
      _FeatureItem(
        icon: Icons.settings_rounded,
        label: '设置',
        color: const Color(0xFF52C41A),
        onTap: () => context.push(AppRoutes.settings),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('功能入口', style: AppTextStyles.subtitle1),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(feature);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature) {
    return GestureDetector(
      onTap: feature.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(feature.icon, color: feature.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            feature.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAnniversaries(BuildContext context, List anniversaries) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('即将到来', style: AppTextStyles.subtitle1),
              TextButton(
                onPressed: () => context.go(AppRoutes.anniversary),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...anniversaries
              .take(3)
              .map((anniversary) => _buildAnniversaryCard(anniversary)),
        ],
      ),
    );
  }

  Widget _buildAnniversaryCard(dynamic anniversary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.cardDecorationSmall,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                anniversary.icon ?? '💝',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anniversary.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  anniversary.eventDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: anniversary.isToday
                  ? AppColors.primary
                  : AppColors.primaryLighter,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              anniversary.displayText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: anniversary.isToday
                    ? AppColors.textWhite
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
