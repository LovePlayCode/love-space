import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routes/app_router.dart';

/// 主页脚手架 - 包含底部导航栏
/// 还原 demo.html 中的底部 tab 样式：首页、日历、纪念日、设置
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/calendar')) return 1;
    if (location.startsWith('/anniversary')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.calendar);
        break;
      case 2:
        context.go(AppRoutes.anniversary);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 56 + bottomPadding,
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 首页 - cottage 图标
            _NavItem(
              icon: Icons.cottage_outlined,
              filledIcon: Icons.cottage_rounded,
              label: '首页',
              isSelected: selectedIndex == 0,
              onTap: () => _onItemTapped(context, 0),
            ),
            // 日历 - calendar_month 图标
            _NavItem(
              icon: Icons.calendar_month_outlined,
              filledIcon: Icons.calendar_month_rounded,
              label: '日历',
              isSelected: selectedIndex == 1,
              onTap: () => _onItemTapped(context, 1),
            ),
            // 纪念日 - favorite 图标
            _NavItem(
              icon: Icons.favorite_outline_rounded,
              filledIcon: Icons.favorite_rounded,
              label: '纪念日',
              isSelected: selectedIndex == 2,
              onTap: () => _onItemTapped(context, 2),
            ),
            // 设置 - settings 图标
            _NavItem(
              icon: Icons.settings_outlined,
              filledIcon: Icons.settings_rounded,
              label: '设置',
              isSelected: selectedIndex == 3,
              onTap: () => _onItemTapped(context, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : icon,
                size: 28,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
