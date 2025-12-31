# Flutter 异步机制与 Dart 基础

## 1. Flutter/Dart 单线程模型

Dart 是**单线程**语言，但通过 **Event Loop（事件循环）** 实现异步非阻塞。

### 事件循环机制

```
┌─────────────────────────────────────┐
│           Event Loop                │
│  ┌─────────────────────────────┐    │
│  │    Microtask Queue          │    │  ← 优先级高（Future.then、scheduleMicrotask）
│  │    (微任务队列)              │    │
│  └─────────────────────────────┘    │
│              ↓                      │
│  ┌─────────────────────────────┐    │
│  │    Event Queue              │    │  ← 普通事件（I/O、Timer、用户交互）
│  │    (事件队列)                │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### 执行顺序

1. 执行同步代码
2. 清空微任务队列
3. 从事件队列取一个事件执行
4. 重复 2-3

### 代码示例

```dart
void main() {
  print('1. 同步代码');
  
  Future(() => print('4. Event Queue'));
  
  Future.microtask(() => print('3. Microtask'));
  
  print('2. 同步代码');
}

// 输出顺序: 1 → 2 → 3 → 4
```

## 2. async/await 机制

`async/await` 是语法糖，让异步代码看起来像同步代码。

```dart
// 使用 async/await
Future<void> fetchData() async {
  final result = await api.getData();  // 暂停，让出执行权
  print(result);                        // 数据返回后继续执行
}

// 等价于
Future<void> fetchData() {
  return api.getData().then((result) {
    print(result);
  });
}
```

### await 的本质

- `await` 不会阻塞线程
- 遇到 `await` 时，函数暂停，**让出执行权给 Event Loop**
- 等待的 Future 完成后，后续代码作为微任务加入队列

## 3. 为什么不是多进程/多线程？

```dart
// 这样写不会创建多个线程
for (final path in paths) {
  await processImage(path);  // 串行执行，一个完成才处理下一个
}

// 这样写也是单线程，只是并发调度
await Future.wait([
  processImage(path1),
  processImage(path2),
  processImage(path3),
]);
// 三个任务"同时"开始，但实际是交替执行（I/O等待时切换）
```

### Dart 的真正多线程：Isolate

```dart
// 如果需要真正的并行计算（CPU密集型）
await Isolate.spawn(heavyComputation, data);
```

## 4. 防止重复执行的锁模式

```dart
class MyNotifier {
  bool _isProcessing = false;
  
  Future<void> doSomething() async {
    if (_isProcessing) return;  // 已在处理中，直接返回
    _isProcessing = true;
    
    try {
      await heavyTask();
    } finally {
      _isProcessing = false;  // 确保释放锁
    }
  }
}
```

## 5. 文件名唯一性策略

避免并发写入时文件名冲突：

```dart
// ❌ 毫秒级时间戳可能重复
final filename = '${DateTime.now().millisecondsSinceEpoch}$ext';

// ✅ 微秒级 + 随机数
import 'dart:math';
final timestamp = DateTime.now().microsecondsSinceEpoch;
final random = Random().nextInt(10000);
final filename = '${timestamp}_$random$ext';
```

---

## 关键概念对比

| 概念 | 说明 |
|------|------|
| 同步 | 代码按顺序执行，阻塞后续代码 |
| 异步 | 不阻塞，通过回调/Future 处理结果 |
| 并发 | 单线程交替执行多个任务（Dart 默认） |
| 并行 | 多线程同时执行（需要 Isolate） |
| Event Loop | 调度异步任务的核心机制 |
| Future | 表示一个异步操作的结果 |
| async/await | 让异步代码更易读的语法糖 |
