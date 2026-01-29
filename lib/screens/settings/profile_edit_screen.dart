import 'dart:typed_data';
import 'dart:ui';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F2),
              Color(0xFFFFE4E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              _buildAppBar(),
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // 头像和昵称卡片
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      // 在一起日期卡片
                      _buildDateCard(),
                      const SizedBox(height: 40),
                      // 保存按钮
                      _buildSaveButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顶部导航栏 (demo9: sticky top bar with back button)
  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // 返回按钮 (demo9: size-10 rounded-full bg-white shadow-sm)
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
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
              // 标题 (demo9: text-lg font-bold tracking-wide text-center)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    '编辑甜蜜档案',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 头像和昵称卡片 (demo9: rounded-4xl = 40px, shadow-soft, p-8)
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像区域 (demo9: flex justify-center items-center gap-8)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 我的头像
              _buildAvatarPicker(
                avatar: _myAvatar,
                label: '我',
                onTap: () => _pickAvatar(true),
              ),
              const SizedBox(width: 24),
              // 爱心图标 (demo9: text-primary/30 text-3xl)
              Icon(
                Icons.favorite_rounded,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 24),
              // TA的头像
              _buildAvatarPicker(
                avatar: _partnerAvatar,
                label: 'TA',
                onTap: () => _pickAvatar(false),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // 昵称输入区域 (demo9: flex flex-col gap-6)
          Column(
            children: [
              // 我的昵称
              _buildNicknameField(
                controller: _myNicknameController,
                label: '我的昵称',
                icon: Icons.face_rounded,
                placeholder: '请输入你的昵称',
              ),
              const SizedBox(height: 24),
              // TA的昵称
              _buildNicknameField(
                controller: _partnerNicknameController,
                label: 'TA的昵称',
                icon: Icons.face_6_rounded,
                placeholder: '请输入TA的昵称',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 头像选择器 (demo9: avatar-frame with add-photo-badge)
  Widget _buildAvatarPicker({
    required String? avatar,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gray100,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 头像
                ClipOval(
                  child: avatar != null
                      ? AvatarWidget(imagePath: avatar, size: 80)
                      : Container(
                          width: 80,
                          height: 80,
                          color: AppColors.gray100,
                          child: Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: AppColors.gray300,
                          ),
                        ),
                ),
                // 添加照片按钮 (demo9: add-photo-badge)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 标签 (demo9: text-xs font-bold text-text-secondary)
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 昵称输入框 (demo9: bubbly-input style)
  Widget _buildNicknameField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签 (demo9: text-xs font-bold text-text-secondary ml-2)
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // 输入框 (demo9: bubbly-input rounded-2xl px-5 py-4)
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray100.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.gray100.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.gray300,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 在一起日期卡片 (demo9: rounded-4xl shadow-soft p-6)
  Widget _buildDateCard() {
    return GestureDetector(
      onTap: _selectStartDate,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // 日历图标 (demo9: w-12 h-12 rounded-2xl bg-secondary/20)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 24,
                color: AppColors.orange500,
              ),
            ),
            const SizedBox(width: 16),
            // 日期信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标签 (demo9: text-[10px] font-bold uppercase tracking-wider)
                  const Text(
                    '在一起的日期',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 日期 (demo9: text-base font-bold)
                  Text(
                    _startDate != null
                        ? DateFormat('yyyy年M月d日').format(_startDate!)
                        : '选择日期',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _startDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // 编辑按钮 (demo9: bg-gray-50 p-2 rounded-xl)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.edit_calendar_rounded,
                size: 24,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存按钮 (demo9: w-full bg-primary rounded-full py-5 shadow-lg)
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _isLoading ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '保存更改',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
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
