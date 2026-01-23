import 'package:flutter/material.dart';

/// LoveSpace 应用颜色配置
/// 采用可爱粉色主题，营造温馨甜蜜的视觉氛围
class AppColors {
  AppColors._();

  // 主色调 - 可爱粉色系 (demo8: #FF8FA3)
  static const Color primary = Color(0xFFFF8FA3);      // Soft Pink
  static const Color primaryLight = Color(0xFFFFB8C1);
  static const Color primaryLighter = Color(0xFFFFC8D0);
  static const Color primaryDark = Color(0xFFE86F85);  // Darker Pink

  // 辅助色 (demo8)
  static const Color secondary = Color(0xFFFFD6A5);    // Peach/Cream
  static const Color accent = Color(0xFFA0E7E5);       // Teal accent

  // 背景色 (demo8: #FFF9F5)
  static const Color background = Color(0xFFFFF9F5);   // Warm Cream Background
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundPink = Color(0xFFFFF0F3);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF2D2424);
  static const Color surfaceDark = Color(0xFF3B3030);

  // 文字颜色 (demo8: text-primary: #4A403A, text-secondary: #9C8E88)
  static const Color textPrimary = Color(0xFF4A403A);  // Brownish text (softer)
  static const Color textSecondary = Color(0xFF9C8E88);
  static const Color textHint = Color(0xFFB8A8A3);
  static const Color textWhite = Color(0xFFFFFFFF);

  // demo8 特有颜色
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color pink100 = Color(0xFFFCE7F3);
  static const Color pink200 = Color(0xFFFBCFE8);
  static const Color pink400 = Color(0xFFF472B6);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red500 = Color(0xFFEF4444);
  static const Color green100 = Color(0xFFDCFCE7);
  static const Color green600 = Color(0xFF16A34A);
  static const Color yellow50 = Color(0xFFFEFCE8);
  static const Color yellow100 = Color(0xFFFEF3C7);
  static const Color yellow300 = Color(0xFFFDE047);
  static const Color yellow600 = Color(0xFFCA8A04);
  static const Color orange100 = Color(0xFFFFEDD5);
  static const Color orange500 = Color(0xFFF97316);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray800 = Color(0xFF1F2937);

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
