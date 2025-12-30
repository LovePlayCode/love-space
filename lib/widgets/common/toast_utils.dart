import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

/// Toast 工具类 - 顶部显示，使用 awesome_snackbar_content
class ToastUtils {
  static void showSuccess(BuildContext context, String message) {
    _showTopToast(
      context,
      title: '成功',
      message: message,
      contentType: ContentType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    _showTopToast(
      context,
      title: '错误',
      message: message,
      contentType: ContentType.failure,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showTopToast(
      context,
      title: '警告',
      message: message,
      contentType: ContentType.warning,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showTopToast(
      context,
      title: '提示',
      message: message,
      contentType: ContentType.help,
    );
  }

  static void _showTopToast(
    BuildContext context, {
    required String title,
    required String message,
    required ContentType contentType,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopToast(
        title: title,
        message: message,
        contentType: contentType,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopToast extends StatefulWidget {
  final String title;
  final String message;
  final ContentType contentType;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopToast({
    required this.title,
    required this.message,
    required this.contentType,
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
            child: AwesomeSnackbarContent(
              title: widget.title,
              message: widget.message,
              contentType: widget.contentType,
            ),
          ),
        ),
      ),
    );
  }
}
