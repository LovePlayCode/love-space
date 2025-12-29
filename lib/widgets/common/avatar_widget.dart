import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 头像组件
class AvatarWidget extends StatelessWidget {
  final String? imagePath;
  final double size;
  final IconData defaultIcon;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const AvatarWidget({
    super.key,
    this.imagePath,
    this.size = 60,
    this.defaultIcon = Icons.person_rounded,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryLighter,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? AppColors.primaryLight,
                  width: 3,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        );
      }
    }
    return _buildDefaultIcon();
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: AppColors.primaryLighter,
      child: Icon(
        defaultIcon,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

/// 双头像组件（情侣头像）
class CoupleAvatarWidget extends StatelessWidget {
  final String? myAvatar;
  final String? partnerAvatar;
  final double avatarSize;
  final double overlap;
  final VoidCallback? onMyAvatarTap;
  final VoidCallback? onPartnerAvatarTap;

  const CoupleAvatarWidget({
    super.key,
    this.myAvatar,
    this.partnerAvatar,
    this.avatarSize = 70,
    this.overlap = 20,
    this.onMyAvatarTap,
    this.onPartnerAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: avatarSize * 2 + 40 - overlap,
      height: avatarSize + 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 我的头像
          Positioned(
            left: 0,
            child: AvatarWidget(
              imagePath: myAvatar,
              size: avatarSize,
              defaultIcon: Icons.person_rounded,
              onTap: onMyAvatarTap,
            ),
          ),
          // 爱心图标
          Positioned(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          // 对方头像
          Positioned(
            right: 0,
            child: AvatarWidget(
              imagePath: partnerAvatar,
              size: avatarSize,
              defaultIcon: Icons.person_rounded,
              onTap: onPartnerAvatarTap,
            ),
          ),
        ],
      ),
    );
  }
}
