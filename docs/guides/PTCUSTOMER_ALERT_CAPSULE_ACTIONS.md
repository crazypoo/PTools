# PTCustomerAlertController 胶囊操作指南

## 目标 / Goal / Objetivo

PTCustomerAlertController 在 iOS 17+ 保留原有公开初始化和回调，同时把操作按钮统一为可访问的胶囊布局。iOS 26 会根据背景表面选择原生按钮材质；旧系统、降低透明度和高对比度场景使用稳定的颜色兜底。

The controller keeps its existing public initializer and callback on iOS 17+, while rendering actions as accessible capsules. On iOS 26 the button material follows the alert surface; older systems, Reduce Transparency, and high-contrast environments use an opaque fallback.

El controlador conserva su inicializador y callback públicos en iOS 17+, y muestra las acciones como cápsulas accesibles. En iOS 26 el material sigue la superficie de la alerta; en sistemas anteriores, con transparencia reducida o alto contraste se usa un fallback opaco.

## 基础用法 / Basic usage / Uso básico

~~~swift
let alert = PTCustomerAlertController(
    title: "保存更改？",
    buttons: ["保存", "取消"],
    buttonsColors: [.systemBlue, .secondaryLabel],
    actionStyles: [.default, .cancel]
)

alert.bottomButtonTapCallback = { title, originalIndex in
    // originalIndex always refers to the original buttons array.
    print(title, originalIndex)
}

PTAlertManager.show(alert)
~~~

originalIndex 始终对应传入 buttons 数组的索引。按钮为了符合系统习惯改变视觉顺序时，回调索引不会改变。

## 配置按钮外观 / Button appearance / Apariencia

~~~swift
var appearance = PTCustomerAlertAppearance.default
appearance.buttonAppearance = PTCustomerAlertButtonAppearance(
    visualStyle: .automatic,
    horizontalSpacing: 12,
    verticalSpacing: 8,
    sectionInsets: .init(top: 10, left: 18, bottom: 18, right: 18),
    titleHorizontalInsets: 16,
    primaryActionIndex: 0
)

let alert = PTCustomerAlertController(
    title: "操作确认",
    buttons: ["确认", "取消"],
    buttonsColors: [.systemBlue, .secondaryLabel],
    actionStyles: [.default, .cancel],
    appearance: appearance
)
~~~

可选样式：

- automatic：默认使用不与外层玻璃重复叠加的系统填充/着色按钮。
- capsule：使用兼容 iOS 17+ 的不透明胶囊颜色。
- glassPreferred：在非原生玻璃外层且系统支持时使用 iOS 26 原生 Glass；其他情况自动回退。

Use automatic for the normal alert surface, capsule for an explicit opaque capsule, and glassPreferred only when the surrounding surface is not already native glass.

## 按钮排列 / Ordering / Orden

- 单按钮：按钮作为主操作。
- 双按钮：明确存在取消和主操作时，横排取消在左、主操作在右；空间不足切换为竖排，主操作在上、取消在下。
- 三个及以上：纵向排列并在达到最大高度后滚动，不再创建分割线。
- primaryActionIndex 可以显式指定主操作；未指定时只在存在唯一默认操作时自动推断。

## 可访问性和动态尺寸 / Accessibility and Dynamic Type / Accesibilidad

按钮标题支持多行和 Dynamic Type。辅助功能尺寸会优先使用竖向排列；Reduce Transparency 会关闭透明材质；Reduce Motion 继续由基础 Alert 动画策略处理。操作按钮不使用扩大的点击区域，避免相邻胶囊发生命中重叠。

Action callbacks remain MainActor-isolated through the controller presentation path. The controller does not pass UIKit objects across actors.

## 兼容入口 / Compatibility / Compatibilidad

UIAlertController+PTEX 的 base_alertVC、base_textfield_alertVC 和其他旧入口继续可用，并通过 PTCustomerAlertController 的 canonical layout 渲染按钮。现有 buttons、buttonsColors、buttonsFont、actionStyles 和 bottomButtonTapCallback 签名不变。

## Demo 验证 / Demo matrix / Matriz de Demo

Example 的 Alert → Alert Capsule Lab 覆盖：

1. 单按钮。
2. 双按钮主操作/取消操作。
3. 长标题和长按钮文案。
4. 20 个按钮的滚动列表。
5. 显式 Glass 首选和兼容回退。
6. 空内容与关闭操作。

测试时还应切换深色/浅色、Dynamic Type、VoiceOver、Reduce Transparency、Reduce Motion、旋转、键盘和 iPhone Duo 的可视区域。
