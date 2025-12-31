# Flutter 图片批量导入最佳实践

## 1. 图片选择器限制

使用 `multi_image_picker` 或类似库时，`maxImages` 参数限制用户可选择的图片数量：

```dart
final images = await picker.pickMultiImage(maxImages: 100);
// 内部实现：selectedImages.take(maxImages)
```

## 2. 批量导入的问题与解决

### 问题 1：大量图片导致 UI 卡顿

**原因**：同时处理太多图片，阻塞 Event Loop

**解决**：分批串行处理

```dart
Future<void> importImages(List<String> paths) async {
  for (final path in paths) {
    await processImage(path);
    // 每处理完一张，更新进度
    updateProgress(current, total);
  }
}
```

### 问题 2：文件名重复

**原因**：并发处理时，毫秒级时间戳可能相同

**解决**：微秒时间戳 + 随机数 + 数据库去重

```dart
// 生成唯一文件名
final timestamp = DateTime.now().microsecondsSinceEpoch;
final random = Random().nextInt(10000);
final filename = '${timestamp}_$random$extension';

// 数据库层面去重
Future<int?> insertMediaItem(MediaItem item) async {
  // 检查是否已存在相同路径
  final existing = await db.query(
    'media',
    where: 'local_path = ?',
    whereArgs: [item.localPath],
  );
  if (existing.isNotEmpty) {
    return null;  // 已存在，跳过
  }
  return await db.insert('media', item.toMap());
}
```

### 问题 3：用户重复点击导入按钮

**解决**：添加导入锁

```dart
bool _isImporting = false;

Future<void> pickAndImportImages() async {
  if (_isImporting) return;  // 防止重复触发
  _isImporting = true;
  
  try {
    // 1. 选择图片
    final paths = await pickImages();
    
    // 2. 路径去重
    final uniquePaths = paths.toSet().toList();
    
    // 3. 串行导入
    for (final path in uniquePaths) {
      await importSingleImage(path);
    }
  } finally {
    _isImporting = false;
  }
}
```

## 3. 导入进度展示

使用状态管理显示进度弹窗：

```dart
// 定义进度状态
enum ImportStage { idle, selecting, importing }

class ImportProgress {
  final ImportStage stage;
  final int completed;
  final int total;
  
  double get percentage => total > 0 ? completed / total : 0;
}

// Provider
final importProgressProvider = StateProvider<ImportProgress>((ref) {
  return ImportProgress(stage: ImportStage.idle, completed: 0, total: 0);
});

// 更新进度
ref.read(importProgressProvider.notifier).state = ImportProgress(
  stage: ImportStage.importing,
  completed: i + 1,
  total: paths.length,
);
```

## 4. 完整导入流程

```
用户点击导入
    ↓
检查 _isImporting 锁
    ↓
显示"正在加载图片"弹窗
    ↓
调用系统图片选择器
    ↓
获取选中图片路径列表
    ↓
路径去重（Set）
    ↓
切换到"正在导入 x/y"
    ↓
串行处理每张图片：
  - 生成唯一文件名
  - 复制到应用目录
  - 数据库去重检查
  - 插入数据库
  - 更新进度
    ↓
关闭弹窗，刷新列表
    ↓
释放 _isImporting 锁
```

## 5. 调试技巧

```dart
// 打印选中的图片路径
debugPrint('Selected images: $selectedPaths');

// 在 VS Code / Android Studio 的 Debug Console 查看
// 或使用 flutter logs 命令
```
