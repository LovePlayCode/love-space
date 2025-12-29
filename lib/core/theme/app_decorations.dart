import 'package:flutter/material.dart';
import 'app_colors.dart';

/// LoveSpace 应用装饰样式配置
class AppDecorations {
  AppDecorations._();

  // 卡片装饰
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get cardDecorationSmall => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColorLight,
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // 渐变卡片装饰
  static BoxDecoration get gradientCardDecoration => BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // 主色渐变装饰
  static BoxDecoration get primaryGradientDecoration => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // 圆形头像装饰
  static BoxDecoration avatarDecoration({double size = 80}) => BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColors.primaryLight,
      width: 3,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // 输入框装饰
  static BoxDecoration get inputDecoration => BoxDecoration(
    color: AppColors.backgroundWhite,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppColors.border),
  );

  // 标签装饰
  static BoxDecoration get tagDecoration => BoxDecoration(
    color: AppColors.primaryLighter,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration get tagDecorationActive => BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(20),
  );

  // 底部导航栏装饰
  static BoxDecoration get bottomNavDecoration => BoxDecoration(
    color: AppColors.backgroundWhite,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 20,
        offset: const Offset(0, -4),
      ),
    ],
  );

  // 浮动按钮装饰
  static BoxDecoration get fabDecoration => BoxDecoration(
    gradient: AppColors.primaryGradient,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.4),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // 图片容器装饰
  static BoxDecoration get imageContainerDecoration => BoxDecoration(
    color: AppColors.backgroundPink,
    borderRadius: BorderRadius.circular(12),
  );

  // 日历日期装饰
  static BoxDecoration get calendarTodayDecoration => BoxDecoration(
    color: AppColors.primaryLighter,
    shape: BoxShape.circle,
  );

  static BoxDecoration get calendarSelectedDecoration => BoxDecoration(
    color: AppColors.primary,
    shape: BoxShape.circle,
  );

  static BoxDecoration get calendarMarkerDecoration => BoxDecoration(
    color: AppColors.primary,
    shape: BoxShape.circle,
  );

  // 心情标记装饰
  static BoxDecoration moodDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color, width: 1),
  );
}

/// 常用间距
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // 页面边距
  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets pageVerticalPadding = EdgeInsets.symmetric(vertical: 16);

  // 卡片内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(12);

  // 列表项间距
  static const double listItemSpacing = 12;
  static const double gridSpacing = 12;
}

/// 常用圆角
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double round = 999;
}

/// 常用动画时长
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}
