import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/couple_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/common/avatar_widget.dart';
import '../../widgets/common/toast_utils.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late TextEditingController _myNicknameController;
  late TextEditingController _partnerNicknameController;
  DateTime? _startDate;
  String? _myAvatar;
  String? _partnerAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _myNicknameController = TextEditingController();
    _partnerNicknameController = TextEditingController();
    _loadCurrentInfo();
  }

  @override
  void dispose() {
    _myNicknameController.dispose();
    _partnerNicknameController.dispose();
    super.dispose();
  }

  void _loadCurrentInfo() {
    final coupleInfo = ref.read(coupleProvider).value;
    if (coupleInfo != null) {
      _myNicknameController.text = coupleInfo.myNickname;
      _partnerNicknameController.text = coupleInfo.partnerNickname;
      _startDate = coupleInfo.startDate;
      _myAvatar = coupleInfo.myAvatar;
      _partnerAvatar = coupleInfo.partnerAvatar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头像区域
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('头像', style: AppTextStyles.subtitle2),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAvatarPicker(
                      avatar: _myAvatar,
                      label: '我',
                      onTap: () => _pickAvatar(true),
                    ),
                    const SizedBox(width: 40),
                    const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 40),
                    _buildAvatarPicker(
                      avatar: _partnerAvatar,
                      label: 'TA',
                      onTap: () => _pickAvatar(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 昵称区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('昵称', style: AppTextStyles.subtitle2),
                const SizedBox(height: 16),
                TextField(
                  controller: _myNicknameController,
                  decoration: const InputDecoration(
                    labelText: '我的昵称',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _partnerNicknameController,
                  decoration: const InputDecoration(
                    labelText: 'TA的昵称',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 恋爱日期区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('在一起的日子', style: AppTextStyles.subtitle2),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundPink,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _startDate != null
                                ? DateFormat('yyyy年MM月dd日').format(_startDate!)
                                : '选择你们在一起的日期',
                            style: TextStyle(
                              fontSize: 16,
                              color: _startDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_startDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLighter,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '已经在一起 ${_calculateDays()} 天',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker({
    required String? avatar,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              AvatarWidget(imagePath: avatar, size: 80),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundWhite,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.textWhite,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  int _calculateDays() {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
    );
    return today.difference(start).inDays + 1;
  }

  Future<void> _pickAvatar(bool isMe) async {
    final mediaService = MediaService();
    final hasPermission = await mediaService.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ToastUtils.showError(context, '需要相册访问权限');
      }
      return;
    }

    // 获取相册
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    // 获取最近的图片
    final assets = await albums.first.getAssetListPaged(page: 0, size: 100);
    if (assets.isEmpty) return;

    // 显示图片选择器
    if (!mounted) return;
    final selected = await showModalBottomSheet<AssetEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AvatarPickerSheet(assets: assets),
    );

    if (selected == null) return;

    // 获取文件并保存
    final file = await selected.originFile;
    if (file == null) return;

    final savedPath = await mediaService.saveFileToAppDir(file);

    setState(() {
      if (isMe) {
        _myAvatar = savedPath;
      } else {
        _partnerAvatar = savedPath;
      }
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textWhite,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    final myNickname = _myNicknameController.text.trim();
    final partnerNickname = _partnerNicknameController.text.trim();

    if (myNickname.isEmpty || partnerNickname.isEmpty) {
      ToastUtils.showError(context, '请填写昵称');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(coupleProvider.notifier);

      await notifier.setMyNickname(myNickname);
      await notifier.setPartnerNickname(partnerNickname);

      if (_myAvatar != null) {
        await notifier.setMyAvatar(_myAvatar!);
      }
      if (_partnerAvatar != null) {
        await notifier.setPartnerAvatar(_partnerAvatar!);
      }
      if (_startDate != null) {
        await notifier.setStartDate(_startDate!);
      }

      await notifier.refresh();

      if (mounted) {
        ToastUtils.showSuccess(context, '保存成功');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, '保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

/// 头像选择器 Sheet
class _AvatarPickerSheet extends StatelessWidget {
  final List<AssetEntity> assets;

  const _AvatarPickerSheet({required this.assets});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '选择头像',
                  style: AppTextStyles.subtitle1,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: assets.length,
              itemBuilder: (context, index) {
                final asset = assets[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, asset),
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(
                      const ThumbnailSize(200, 200),
                      quality: 80,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(color: AppColors.divider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
