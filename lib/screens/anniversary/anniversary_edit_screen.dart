import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/anniversary.dart';
import '../../providers/anniversary_provider.dart';
import '../../widgets/common/toast_utils.dart';

class AnniversaryEditScreen extends ConsumerStatefulWidget {
  final String? anniversaryId;

  const AnniversaryEditScreen({super.key, this.anniversaryId});

  @override
  ConsumerState<AnniversaryEditScreen> createState() => _AnniversaryEditScreenState();
}

class _AnniversaryEditScreenState extends ConsumerState<AnniversaryEditScreen> {
  // 辅助色
  static const Color secondaryGreen = Color(0xFF88D4AB);
  static const Color secondaryYellow = Color(0xFFFFD93D);
  static const Color secondaryBlue = Color(0xFF6BCBFF);
  static const Color backgroundLight = Color(0xFFFFF0F0);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = true;
  int _selectedIconIndex = 0;

  // 图标列表
  static const List<_IconItem> _iconItems = [
    _IconItem(icon: Icons.favorite, color: AppColors.primary),
    _IconItem(icon: Icons.cake, color: secondaryBlue),
    _IconItem(icon: Icons.flight_takeoff, color: secondaryGreen),
    _IconItem(icon: Icons.home, color: secondaryYellow),
    _IconItem(icon: Icons.restaurant, color: Color(0xFFFB923C)),
    _IconItem(icon: Icons.movie, color: Color(0xFFA78BFA)),
    _IconItem(icon: Icons.card_giftcard, color: Color(0xFFF472B6)),
    _IconItem(icon: Icons.photo_camera, color: Color(0xFF60A5FA)),
  ];

  // 图标对应的 emoji
  static const List<String> _iconEmojis = ['❤️', '🎂', '✈️', '🏠', '🍽️', '🎬', '🎁', '📷'];

  bool get isEditing => widget.anniversaryId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    
    if (isEditing) {
      _loadExistingAnniversary();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _loadExistingAnniversary() {
    final id = int.tryParse(widget.anniversaryId!);
    if (id != null) {
      final anniversary = ref.read(anniversaryProvider.notifier).getById(id);
      if (anniversary != null) {
        _titleController.text = anniversary.title;
        _selectedDate = anniversary.date;
        _isRecurring = anniversary.isRecurring;
        // 匹配图标
        final iconIndex = _iconEmojis.indexOf(anniversary.icon ?? '❤️');
        _selectedIconIndex = iconIndex >= 0 ? iconIndex : 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // 点点背景
          const _DotBackground(),
          // 主内容
          SafeArea(
            child: Column(
              children: [
                // 顶部导航栏
                _buildHeader(context),
                // 表单内容
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        const SizedBox(height: 8),
                        // 名称和日期卡片
                        _buildNameDateCard(),
                        const SizedBox(height: 20),
                        // 每年重复开关
                        _buildRepeatCard(),
                        const SizedBox(height: 20),
                        // 图标选择
                        _buildIconCard(),
                        const SizedBox(height: 24),
                        // 保存按钮
                        _buildSaveButton(),
                        const SizedBox(height: 16),
                        // 提示文字
                        const Center(
                          child: Text(
                            '所有数据仅保存在您的手机中',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 30,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryDark,
                  size: 18,
                ),
              ),
            ),
          ),
          // 标题
          Text(
            isEditing ? '编辑日子' : '添加新日子',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          // 占位
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildNameDateCard() {
    final dateFormat = DateFormat('yyyy年MM月dd日');
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日子名称
          _buildLabel(Icons.edit_note_rounded, '日子名称'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
            decoration: InputDecoration(
              hintText: '例如：恋爱纪念日',
              hintStyle: const TextStyle(
                fontSize: 18,
                color: Color(0xFFD1D5DB),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入日子名称';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // 选择日期
          _buildLabel(Icons.calendar_today_rounded, '选择日期'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const Icon(
                    Icons.event_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: secondaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.autorenew_rounded,
                color: secondaryYellow,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 文字
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '每年重复',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '自动为您计算周岁',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          // 开关
          GestureDetector(
            onTap: () => setState(() => _isRecurring = !_isRecurring),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: _isRecurring ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _isRecurring ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(Icons.mood_rounded, '图标选择'),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: _iconItems.length,
            itemBuilder: (context, index) {
              final item = _iconItems[index];
              final isSelected = _selectedIconIndex == index;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedIconIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      item.icon,
                      size: 30,
                      color: isSelected ? Colors.white : item.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? '保存修改' : '保存日子',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF374151),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final anniversary = Anniversary(
      id: isEditing ? int.tryParse(widget.anniversaryId!) : null,
      title: _titleController.text.trim(),
      eventDate: dateStr,
      isRecurring: _isRecurring,
      type: 'custom',
      icon: _iconEmojis[_selectedIconIndex],
    );

    bool success;
    if (isEditing) {
      success = await ref.read(anniversaryProvider.notifier).updateAnniversary(anniversary);
    } else {
      final result = await ref.read(anniversaryProvider.notifier).addAnniversary(anniversary);
      success = result != null;
    }

    if (success && mounted) {
      ToastUtils.showSuccess(context, isEditing ? '修改成功' : '添加成功');
      context.pop();
    }
  }
}

/// 图标项
class _IconItem {
  final IconData icon;
  final Color color;

  const _IconItem({required this.icon, required this.color});
}

/// 点点背景
class _DotBackground extends StatelessWidget {
  const _DotBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFFFF0F0),
        child: CustomPaint(
          painter: _DotPainter(),
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    const dotRadius = 3.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
