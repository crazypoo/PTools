# PTActionSheet / PTAlert Overlay 集成边界

## ActionSheet

- iPhone 保持底部 ActionSheet 语义。
- iPad 或明确指定 Anchor 时可使用系统 `UIPopoverPresentationController`。
- 自定义 Anchor 定位应使用 `PTAnchor` 与 `PTPopoverPositioningEngine`，不得复制 Scene/Window/Registry。

## Alert

- `PTAlertManager` 和 `PTCustomerAlertController` 继续负责标题、消息、按钮和 Liquid Glass 排版。
- Alert 不转换为 `PTPopover(style: .alert)`。
- Alert 只应复用 Overlay 的 Scene、Z-order、Transition、Backdrop、Focus 和 Dismiss 原语。
- 已修复的 title-only、message-only、长文本和按钮布局行为必须单独回归。

