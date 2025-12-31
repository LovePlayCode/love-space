# Flutter 组件学习笔记

## 1. AsyncValue.when

Riverpod 提供的异步状态处理模式，用于优雅地处理 loading、error、data 三种状态。

```dart
asyncValue.when(
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(),
  data: (data) => DataWidget(data),
)
```

## 2. IgnorePointer

阻止子组件接收任何指针事件（点击、拖拽等），事件会"穿透"传递给下层组件。

```dart
IgnorePointer(
  ignoring: true,  // true=忽略事件（默认），false=正常响应
  child: YourWidget(),
)
```

**使用场景**：覆盖层装饰（如选中边框），只需要视觉效果但不拦截点击事件。

## 3. Positioned.fill

`Positioned` 的便捷构造函数，让子组件填满整个 `Stack` 父容器。

```dart
Stack(
  children: [
    MainContent(),
    Positioned.fill(  // 等同于 left:0, right:0, top:0, bottom:0
      child: OverlayWidget(),
    ),
  ],
)
```

## 4. Stack

层叠布局组件，子组件按顺序堆叠，后面的覆盖前面的。

```dart
Stack(
  children: [
    BottomLayer(),   // 最底层
    MiddleLayer(),   // 中间层
    TopLayer(),      // 最上层
  ],
)
```

## 5. Wrap

流式布局组件，子组件超出宽度时自动换行。

```dart
Wrap(
  spacing: 8,      // 水平间距
  runSpacing: 8,   // 行间距
  children: [...],
)
```

**对比 GridView**：Wrap 更适合在 Dialog/ScrollView 中使用，不会有布局冲突。

## 6. MasonryGridView

瀑布流布局组件（来自 `flutter_staggered_grid_view` 包），支持不等高的网格布局。

```dart
MasonryGridView.count(
  crossAxisCount: 2,      // 列数
  mainAxisSpacing: 12,    // 主轴间距
  crossAxisSpacing: 12,   // 交叉轴间距
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(),
)
```

## 7. SingleChildScrollView

单子组件滚动视图，当内容超出屏幕时提供滚动能力。

```dart
SingleChildScrollView(
  scrollDirection: Axis.vertical,  // 滚动方向
  child: Column(children: [...]),
)
```

## 8. GestureDetector

手势检测组件，用于监听各种触摸事件。

```dart
GestureDetector(
  onTap: () => print('点击'),
  onLongPress: () => print('长按'),
  onDoubleTap: () => print('双击'),
  child: YourWidget(),
)
```

---

## 常用组合模式

### 选中效果不影响布局

```dart
Stack(
  children: [
    Container(...),  // 主体内容，尺寸固定
    if (isSelected)
      Positioned.fill(
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue, width: 3),
            ),
          ),
        ),
      ),
  ],
)
```
