import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Toast 工具类 - 顶部显示
class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showTopSnackBar(
      context,
      message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_rounded,
    );
  }

  static void _showTopSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopToast(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
