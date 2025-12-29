import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/app_router.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/common/avatar_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupleAsync = ref.watch(coupleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 情侣信息卡片
          coupleAsync.when(
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
            data: (coupleInfo) => GestureDetector(
              onTap: () => context.push(AppRoutes.profileEdit),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CoupleAvatarWidget(
                      myAvatar: coupleInfo.myAvatar,
                      partnerAvatar: coupleInfo.partnerAvatar,
                      avatarSize: 50,
                      overlap: 15,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${coupleInfo.myNickname} & ${coupleInfo.partnerNickname}',
                            style: AppTextStyles.subtitle1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '在一起 ${coupleInfo.daysTogetherText} 天',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 设置项
          _buildSettingsSection(
            title: '通用',
            items: [
              _SettingsItem(
                icon: Icons.palette_rounded,
                title: '主题设置',
                subtitle: '粉色浪漫',
                onTap: () => _showThemeDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: '数据',
            items: [
              _SettingsItem(
                icon: Icons.backup_rounded,
                title: '备份数据',
                subtitle: '导出数据到本地',
                onTap: () => _showBackupDialog(context),
              ),
              _SettingsItem(
                icon: Icons.restore_rounded,
                title: '恢复数据',
                subtitle: '从备份文件恢复',
                onTap: () => _showRestoreDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: '关于',
            items: [
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                title: '关于 LoveSpace',
                subtitle: '版本 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: AppColors.primary, size: 20),
                    ),
                    title: Text(item.title, style: AppTextStyles.body1),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 68),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题设置'),
        content: const Text('当前版本仅支持粉色浪漫主题，更多主题敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('备份数据'),
        content: const Text('备份功能即将上线，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('恢复功能即将上线，敬请期待！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('LoveSpace'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text(
              '一款专为情侣设计的纯本地存储记录应用，帮助你们记录和珍藏恋爱中的美好时光。',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              '所有数据均存储在本地，保护你们的隐私。',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
