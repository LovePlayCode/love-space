import 'package:flutter/material.dart';

/// LoveSpace 应用颜色配置
/// 采用粉色浪漫主题，营造温馨甜蜜的视觉氛围
class AppColors {
  AppColors._();

  // 主色调 - 浪漫粉色渐变
  static const Color primary = Color(0xFFFF6B8A);
  static const Color primaryLight = Color(0xFFFF8FA3);
  static const Color primaryLighter = Color(0xFFFFB3C1);
  static const Color primaryDark = Color(0xFFFF4D6D);

  // 背景色
  static const Color background = Color(0xFFFFF5F7);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundPink = Color(0xFFFFF0F3);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // 文字颜色
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);

  // 功能色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAAD14);
  static const Color error = Color(0xFFFF4D6D);
  static const Color info = Color(0xFF1890FF);

  // 心情颜色
  static const Color moodHappy = Color(0xFFFFD93D);
  static const Color moodLove = Color(0xFFFF6B8A);
  static const Color moodSad = Color(0xFF6C9BCF);
  static const Color moodAngry = Color(0xFFFF6B6B);
  static const Color moodNeutral = Color(0xFFB8B8B8);

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
  static const Color shadowColor = Color(0x1AFF6B8A);
  static const Color shadowColorLight = Color(0x0DFF6B8A);

  // 分割线颜色
  static const Color divider = Color(0xFFFFE4E9);
  static const Color border = Color(0xFFFFD6DE);
}
