import 'package:flutter/material.dart';

/// LoveSpace 应用颜色配置
/// 采用可爱粉色主题，营造温馨甜蜜的视觉氛围
class AppColors {
  AppColors._();

  // 主色调 - 可爱粉色系
  static const Color primary = Color(0xFFFF9EAA);      // Soft Pink
  static const Color primaryLight = Color(0xFFFFB8C1);
  static const Color primaryLighter = Color(0xFFFFC8D0);
  static const Color primaryDark = Color(0xFFFF758F);  // Darker Pink

  // 辅助色
  static const Color secondary = Color(0xFFFFE5B4);    // Peach/Cream
  static const Color accent = Color(0xFFFFD93D);       // Pop Yellow

  // 背景色
  static const Color background = Color(0xFFFFFBF0);   // Warm Cream Background
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundPink = Color(0xFFFFF0F3);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 文字颜色
  static const Color textPrimary = Color(0xFF5D4037);  // Brownish text (softer)
  static const Color textSecondary = Color(0xFF9E837D);
  static const Color textHint = Color(0xFFB8A8A3);
  static const Color textWhite = Color(0xFFFFFFFF);

  // 功能色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF1890FF);

  // 心情颜色
  static const Color moodHappy = Color(0xFFFFD93D);
  static const Color moodLove = Color(0xFFFF9EAA);
  static const Color moodSad = Color(0xFF6C9BCF);
  static const Color moodAngry = Color(0xFFFF6B6B);
  static const Color moodNeutral = Color(0xFFB8B8B8);

  // 边框颜色
  static const Color borderCute = Color(0xFFF8C8DC);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, primaryDark],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundPink, background],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F7)],
  );

  // 阴影颜色
  static const Color shadowColor = Color(0x26FF9EAA);
  static const Color shadowColorLight = Color(0x0DFF9EAA);

  // 卡片可爱阴影
  static List<BoxShadow> get cuteShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cuteChunkyShadow => [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  // 分割线颜色
  static const Color divider = Color(0xFFFFE4E9);
  static const Color border = Color(0xFFFFD6DE);
}
