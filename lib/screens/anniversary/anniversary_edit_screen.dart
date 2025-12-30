import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = true;
  String _selectedType = 'custom';
  String _selectedIcon = '💝';

  bool get isEditing => widget.anniversaryId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    
    if (isEditing) {
      _loadExistingAnniversary();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _loadExistingAnniversary() {
    final id = int.tryParse(widget.anniversaryId!);
    if (id != null) {
      final anniversary = ref.read(anniversaryProvider.notifier).getById(id);
      if (anniversary != null) {
        _titleController.text = anniversary.title;
        _noteController.text = anniversary.note ?? '';
        _selectedDate = anniversary.date;
        _isRecurring = anniversary.isRecurring;
        _selectedType = anniversary.type ?? 'custom';
        _selectedIcon = anniversary.icon ?? '💝';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? '编辑纪念日' : '添加纪念日'),
        backgroundColor: AppColors.background,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题输入
            _buildSection(
              title: '纪念日名称',
              child: TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例如：在一起纪念日',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入纪念日名称';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            // 日期选择
            _buildSection(
              title: '日期',
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('yyyy年MM月dd日').format(_selectedDate),
                        style: AppTextStyles.body1,
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 类型选择
            _buildSection(
              title: '类型',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.anniversaryTypes.entries.map((entry) {
                  final isSelected = _selectedType == entry.key;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = entry.key;
                        _selectedIcon = AppConstants.anniversaryIcons[entry.key] ?? '💝';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppConstants.anniversaryIcons[entry.key] ?? '💝',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.textWhite : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // 图标选择
            _buildSection(
              title: '图标',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppConstants.anniversaryIcons.values.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLighter : AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // 是否每年重复
            _buildSection(
              title: '重复',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('每年重复', style: AppTextStyles.body1),
                    ),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) => setState(() => _isRecurring = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 备注
            _buildSection(
              title: '备注（可选）',
              child: TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '添加一些备注...',
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle2,
        ),
        const SizedBox(height: 8),
        child,
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
      type: _selectedType,
      icon: _selectedIcon,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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
