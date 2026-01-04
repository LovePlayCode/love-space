import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_item.dart';
import '../services/database_service.dart';

/// 数据库服务 Provider
final _dbServiceProvider = Provider((ref) => DatabaseService());

/// 指定日期的待办事项列表 Provider
final todoListProvider = StateNotifierProvider.family<TodoListNotifier, AsyncValue<List<TodoItem>>, String>(
  (ref, dateStr) => TodoListNotifier(ref.watch(_dbServiceProvider), dateStr),
);

/// 有待办事项的日期集合 Provider
final todoDatesProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.watch(_dbServiceProvider);
  return await db.getTodoDates();
});

/// 待办事项列表状态管理器
class TodoListNotifier extends StateNotifier<AsyncValue<List<TodoItem>>> {
  final DatabaseService _db;
  final String _dateStr;

  TodoListNotifier(this._db, this._dateStr) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  /// 加载待办事项
  Future<void> loadTodos() async {
    try {
      state = const AsyncValue.loading();
      final todos = await _db.getTodosByDate(_dateStr);
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 添加待办事项
  Future<void> addTodo(String content) async {
    if (content.trim().isEmpty) return;
    
    final todo = TodoItem(
      content: content.trim(),
      dateStr: _dateStr,
    );
    
    await _db.insertTodo(todo);
    await loadTodos();
  }

  /// 切换完成状态
  Future<void> toggleComplete(int id) async {
    await _db.toggleTodoComplete(id);
    
    // 更新本地状态，避免重新加载
    state.whenData((todos) {
      final updatedTodos = todos.map((todo) {
        if (todo.id == id) {
          return todo.copyWith(isCompleted: !todo.isCompleted);
        }
        return todo;
      }).toList();
      state = AsyncValue.data(updatedTodos);
    });
  }

  /// 删除待办事项
  Future<void> deleteTodo(int id) async {
    await _db.deleteTodo(id);
    
    // 更新本地状态
    state.whenData((todos) {
      final updatedTodos = todos.where((todo) => todo.id != id).toList();
      state = AsyncValue.data(updatedTodos);
    });
  }

  /// 更新待办事项内容
  Future<void> updateTodo(int id, String content) async {
    if (content.trim().isEmpty) return;
    
    state.whenData((todos) async {
      final todo = todos.firstWhere((t) => t.id == id);
      final updatedTodo = todo.copyWith(content: content.trim());
      await _db.updateTodo(updatedTodo);
      await loadTodos();
    });
  }
}
