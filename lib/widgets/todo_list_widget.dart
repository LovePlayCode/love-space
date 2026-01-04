import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/todo_item.dart';
import '../providers/todo_provider.dart';

/// 待办事项列表组件
class TodoListWidget extends ConsumerStatefulWidget {
  final String dateStr;
  final bool showHeader;

  const TodoListWidget({
    super.key,
    required this.dateStr,
    this.showHeader = true,
  });

  @override
  ConsumerState<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends ConsumerState<TodoListWidget> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAdding = false;

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAdding() {
    setState(() => _isAdding = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  void _cancelAdding() {
    setState(() {
      _isAdding = false;
      _inputController.clear();
    });
  }

  Future<void> _submitTodo() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) {
      _cancelAdding();
      return;
    }

    await ref.read(todoListProvider(widget.dateStr).notifier).addTodo(content);
    _inputController.clear();
    // 保持添加状态，方便连续添加
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoListProvider(widget.dateStr));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.checklist_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('待办事项', style: AppTextStyles.subtitle2),
                  ],
                ),
                if (!_isAdding)
                  GestureDetector(
                    onTap: _startAdding,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text(
                            '添加',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          todosAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Center(
              child: Text('加载失败: $e', style: const TextStyle(color: AppColors.textHint)),
            ),
            data: (todos) => _buildTodoList(todos),
          ),
          if (_isAdding) _buildAddInput(),
        ],
      ),
    );
  }

  Widget _buildTodoList(List<TodoItem> todos) {
    if (todos.isEmpty && !_isAdding) {
      return GestureDetector(
        onTap: _startAdding,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: const Center(
            child: Column(
              children: [
                Icon(Icons.add_task_rounded, size: 32, color: AppColors.textHint),
                SizedBox(height: 8),
                Text(
                  '点击添加待办事项',
                  style: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: todos.map((todo) => _TodoItemWidget(
        todo: todo,
        onToggle: () => ref.read(todoListProvider(widget.dateStr).notifier).toggleComplete(todo.id!),
        onDelete: () => _showDeleteConfirm(todo),
      )).toList(),
    );
  }

  Widget _buildAddInput() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundPink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLighter, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_unchecked, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: '添加待办事项...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitTodo(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submitTodo,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _cancelAdding,
            child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(TodoItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办'),
        content: Text('确定要删除「${todo.content}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(todoListProvider(widget.dateStr).notifier).deleteTodo(todo.id!);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 单个待办事项组件
class _TodoItemWidget extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItemWidget({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        onDelete();
        return false; // 由对话框控制删除
      },
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: todo.isCompleted ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: todo.isCompleted ? AppColors.primary : AppColors.textHint,
                    width: 2,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  todo.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: todo.isCompleted ? AppColors.textHint : AppColors.textPrimary,
                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
