import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/routes/app_router.dart';
import '../../providers/couple_provider.dart';
import '../../providers/anniversary_provider.dart';
import '../../providers/album_provider.dart';
import '../../models/media_item.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/loading_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(coupleProvider);
    final upcomingAnniversaries = ref.watch(upcomingAnniversariesProvider);
    final albumAsync = ref.watch(albumProvider);

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
            // 即将到来的纪念日
            SliverToBoxAdapter(
              child: _buildUpcomingAnniversaries(
                context,
                upcomingAnniversaries,
              ),
            ),
            // 最近照片
            SliverToBoxAdapter(
              child: _buildRecentPhotos(context, albumAsync),
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
                        Padding(
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

  Widget _buildUpcomingAnniversaries(BuildContext context, List anniversaries) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
          if (anniversaries.isEmpty)
            _buildEmptyCard(
              icon: Icons.celebration_rounded,
              title: '暂无纪念日',
              subtitle: '点击添加你们的重要日子',
              onTap: () => context.go(AppRoutes.anniversary),
            )
          else
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

  Widget _buildRecentPhotos(BuildContext context, AsyncValue<List<MediaItem>> albumAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近照片', style: AppTextStyles.subtitle1),
              TextButton(
                onPressed: () => context.go(AppRoutes.album),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          albumAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
            error: (_, __) => _buildEmptyCard(
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
              // 取最近6张
              final recentItems = items.take(6).toList();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: recentItems.length,
                itemBuilder: (context, index) {
                  return _buildPhotoCard(context, recentItems[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.album}/detail/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(item.displayPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.divider,
                  child: const Icon(Icons.broken_image_rounded, color: AppColors.textHint),
                ),
              ),
              if (item.isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: AppDecorations.cardDecorationSmall,
        child: Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLighter,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
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
