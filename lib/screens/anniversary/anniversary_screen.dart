import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../models/anniversary.dart';
import '../../providers/anniversary_provider.dart';
import '../../widgets/common/loading_widget.dart';

class AnniversaryScreen extends ConsumerWidget {
  const AnniversaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anniversariesAsync = ref.watch(anniversaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('纪念日'),
        backgroundColor: AppColors.background,
      ),
      body: anniversariesAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: '加载失败',
          onRetry: () => ref.refresh(anniversaryProvider),
        ),
        data: (anniversaries) {
          if (anniversaries.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildAnniversaryList(context, ref, anniversaries);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.anniversaryAdd),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textWhite),
        label: const Text('添加纪念日', style: TextStyle(color: AppColors.textWhite)),
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

  Widget _buildAnniversaryList(BuildContext context, WidgetRef ref, List<Anniversary> anniversaries) {
    // 分组：即将到来、已过去
    final upcoming = anniversaries.where((a) => a.daysUntil >= 0).toList();
    final past = anniversaries.where((a) => a.daysUntil < 0 && !a.isRecurring).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _SectionHeader(title: '即将到来', icon: Icons.upcoming_rounded),
          const SizedBox(height: 12),
          ...upcoming.map((a) => _AnniversaryCard(
            anniversary: a,
            onTap: () => _showAnniversaryOptions(context, ref, a),
          )),
          const SizedBox(height: 24),
        ],
        if (past.isNotEmpty) ...[
          const _SectionHeader(title: '已过去', icon: Icons.history_rounded),
          const SizedBox(height: 12),
          ...past.map((a) => _AnniversaryCard(
            anniversary: a,
            onTap: () => _showAnniversaryOptions(context, ref, a),
          )),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  void _showAnniversaryOptions(BuildContext context, WidgetRef ref, Anniversary anniversary) {
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
              // 纪念日信息
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          anniversary.icon ?? '💝',
                          style: const TextStyle(fontSize: 24),
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
                            style: AppTextStyles.subtitle1,
                          ),
                          Text(
                            anniversary.eventDate,
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
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
                leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('${AppRoutes.anniversaryEdit}?id=${anniversary.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('删除', style: TextStyle(color: AppColors.error)),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Anniversary anniversary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除纪念日'),
        content: Text('确定要删除「${anniversary.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (anniversary.id != null) {
                await ref.read(anniversaryProvider.notifier).deleteAnniversary(anniversary.id!);
              }
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.subtitle2.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _AnniversaryCard extends StatelessWidget {
  final Anniversary anniversary;
  final VoidCallback onTap;

  const _AnniversaryCard({
    required this.anniversary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = anniversary.isToday;
    final isUpcoming = anniversary.isUpcoming;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isToday ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.shadowColorLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.backgroundWhite.withValues(alpha: 0.2)
                    : AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  anniversary.icon ?? '💝',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          anniversary.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.textWhite : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (anniversary.isRecurring)
                        Icon(
                          Icons.repeat_rounded,
                          size: 16,
                          color: isToday ? AppColors.textWhite.withValues(alpha: 0.7) : AppColors.textHint,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    anniversary.eventDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? AppColors.textWhite.withValues(alpha: 0.8)
                          : AppColors.textHint,
                    ),
                  ),
                  if (anniversary.note != null && anniversary.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      anniversary.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isToday
                            ? AppColors.textWhite.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 倒计时
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.backgroundWhite
                    : isUpcoming
                        ? AppColors.primary
                        : AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    isToday
                        ? '🎉'
                        : anniversary.daysUntil >= 0
                            ? '${anniversary.daysUntil}'
                            : '${-anniversary.daysUntil}',
                    style: TextStyle(
                      fontSize: isToday ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: isToday
                          ? AppColors.primary
                          : isUpcoming
                              ? AppColors.textWhite
                              : AppColors.primary,
                    ),
                  ),
                  if (!isToday)
                    Text(
                      anniversary.daysUntil >= 0 ? '天后' : '天前',
                      style: TextStyle(
                        fontSize: 10,
                        color: isUpcoming ? AppColors.textWhite : AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
