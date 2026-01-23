import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
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
      body: Column(
        children: [
          // 顶部导航栏
          _buildAppBar(context),
          // 内容区域
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // 情侣信息卡片
                coupleAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (coupleInfo) => _buildCoupleCard(
                    context,
                    myNickname: coupleInfo.myNickname,
                    partnerNickname: coupleInfo.partnerNickname,
                    daysTogether: coupleInfo.daysTogetherText,
                    myAvatar: coupleInfo.myAvatar,
                    partnerAvatar: coupleInfo.partnerAvatar,
                  ),
                ),
                const SizedBox(height: 24),
                // 我们的故事
                _buildSectionTitle('我们的故事', AppColors.secondary),
                const SizedBox(height: 12),
                _buildStorySection(context, coupleAsync),
                const SizedBox(height: 24),
                // 隐私与安全
                _buildSectionTitle('隐私与安全', AppColors.accent),
                const SizedBox(height: 12),
                _buildPrivacySection(context),
                const SizedBox(height: 24),
                // 数据宝箱
                _buildDataBoxHeader(),
                const SizedBox(height: 12),
                _buildDataBox(context),
                const SizedBox(height: 24),
                // 底部版本信息
                _buildFooter(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // 标题
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Text(
                '设置',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 情侣信息卡片 (demo8: rounded-3xl = 40px)
  Widget _buildCoupleCard(
    BuildContext context, {
    required String myNickname,
    required String partnerNickname,
    required String daysTogether,
    String? myAvatar,
    String? partnerAvatar,
  }) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.profileEdit),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(40), // rounded-3xl = 2.5rem = 40px
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 顶部渐变装饰
            Positioned(
              top: -24,
              left: -24,
              right: -24,
              child: Container(
                height: 128,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 8),
                // 头像区域
                _buildCoupleAvatars(myAvatar, partnerAvatar),
                const SizedBox(height: 16),
                // 昵称
                Text(
                  '$myNickname & $partnerNickname',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // 在一起天数
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '甜蜜相恋 $daysTogether 天',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 编辑按钮 (demo8: rounded-2xl = 32px)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.background,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32), // rounded-2xl = 2rem = 32px
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_square,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '编辑甜蜜档案',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 情侣头像组件
  Widget _buildCoupleAvatars(String? myAvatar, String? partnerAvatar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 他的头像
        _buildAvatarWithLabel(
          avatar: myAvatar,
          label: '他',
          labelColor: AppColors.blue400,
          ringColor: AppColors.blue200,
          bgColor: AppColors.blue100.withValues(alpha: 0.5),
        ),
        // 爱心
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          transform: Matrix4.translationValues(0, 0, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        // 她的头像
        _buildAvatarWithLabel(
          avatar: partnerAvatar,
          label: '她',
          labelColor: AppColors.pink400,
          ringColor: AppColors.pink200,
          bgColor: AppColors.pink100.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  /// 带标签的头像
  Widget _buildAvatarWithLabel({
    required String? avatar,
    required String label,
    required Color labelColor,
    required Color ringColor,
    required Color bgColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2),
            ),
            child: ClipOval(
              child: avatar != null && avatar.isNotEmpty
                  ? AvatarWidget(imagePath: avatar, size: 72, showBorder: false)
                  : Container(
                      color: bgColor,
                      child: Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: labelColor,
                      ),
                    ),
            ),
          ),
        ),
        // 标签
        Positioned(
          bottom: -8,
          left: label == '他' ? null : -8,
          right: label == '她' ? null : -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: label == '他' ? AppColors.blue100 : AppColors.pink100,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 分区标题
  Widget _buildSectionTitle(String title, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 我们的故事区域 (demo8: rounded-3xl = 40px)
  Widget _buildStorySection(BuildContext context, AsyncValue coupleAsync) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(40), // rounded-3xl = 2.5rem = 40px
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // 相恋纪念日
          _buildSettingItem(
            icon: Icons.favorite_rounded,
            iconColor: AppColors.red500,
            iconBgColor: AppColors.red100,
            title: '相恋纪念日',
            subtitle: '故事开始的那一天',
            trailing: _buildDateBadge(coupleAsync),
            onTap: () => context.push(AppRoutes.profileEdit),
            showDivider: true,
            iconRotation: 3,
          ),
          // 纪念日提醒
          _buildSettingItem(
            icon: Icons.event_available_rounded,
            iconColor: AppColors.blue500,
            iconBgColor: AppColors.blue100,
            title: '纪念日提醒',
            subtitle: '不错过每个重要时刻',
            trailing: _buildSwitch(false, (value) {}),
            onTap: null,
            showDivider: false,
            iconRotation: -2,
          ),
        ],
      ),
    );
  }

  /// 日期标签 (demo8: rounded-xl = 24px)
  Widget _buildDateBadge(AsyncValue coupleAsync) {
    String dateText = '未设置';
    coupleAsync.whenData((info) {
      final date = info.startDate;
      dateText = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    });
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24), // rounded-xl = 1.5rem = 24px
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.gray300,
        ),
      ],
    );
  }

  /// 隐私与安全区域 (demo8: rounded-3xl = 40px)
  Widget _buildPrivacySection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(40), // rounded-3xl = 2.5rem = 40px
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: _buildSettingItem(
        icon: Icons.lock_open_rounded,
        iconColor: AppColors.green600,
        iconBgColor: AppColors.green100,
        title: '应用锁',
        subtitle: '面容 ID / 密码保护',
        trailing: _buildSwitch(true, (value) {}),
        onTap: null,
        showDivider: false,
        iconRotation: 1,
      ),
    );
  }

  /// 设置项 (demo8: 图标 rounded-2xl = 32px)
  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    required bool showDivider,
    double iconRotation = 0,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 图标 (demo8: w-12 h-12 rounded-2xl = 32px)
                Transform.rotate(
                  angle: iconRotation * 3.14159 / 180,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(32), // rounded-2xl = 2rem = 32px
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                // 文字
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 80,
            color: AppColors.gray100.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  /// 开关组件
  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.primary : AppColors.gray200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 数据宝箱标题栏
  Widget _buildDataBoxHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.yellow300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '数据宝箱',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // 离线模式标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.yellow50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.yellow100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 14,
                  color: AppColors.yellow600,
                ),
                const SizedBox(width: 4),
                Text(
                  '离线模式',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 数据宝箱 (demo8: rounded-3xl = 40px)
  Widget _buildDataBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(40), // rounded-3xl = 2.5rem = 40px
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰圆形
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.yellow100.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              // 标题区 (demo8: 图标 w-14 h-14 rounded-2xl = 32px)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.yellow100,
                          AppColors.orange100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32), // rounded-2xl = 2rem = 32px
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 30,
                      color: AppColors.orange500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '回忆只属于你们',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LoveSpace 将所有甜蜜点滴保存在你的手机本地。我们无法偷看哦！\n记得把它们放进保险箱（定期备份）。',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 按钮区 (demo8: rounded-xl = 24px)
              Row(
                children: [
                  // 导出备份按钮
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showBackupDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(24), // rounded-xl = 1.5rem = 24px
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ios_share_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '导出备份',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 恢复数据按钮
                  GestureDetector(
                    onTap: () => _showRestoreDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24), // rounded-xl = 1.5rem = 24px
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings_backup_restore_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '恢复数据',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 上次备份信息
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.gray200,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 12,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '上次备份',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '暂无',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 底部版本信息
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Icon(Icons.pets_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Icon(Icons.pets_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'LoveSpace 暖心版 v1.0.0 (Local)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
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
}
