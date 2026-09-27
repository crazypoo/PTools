# Instructions → PooToolsInstructions 迁移

## 依赖替换

删除：

```ruby
pod 'Instructions'
```

改为：

```ruby
pod 'PooTools/Instructions'
```

SwiftPM 改为添加 `PooToolsInstructions` product。旧的 `CoachMarksController`、第三方 Window 和第三方 target 类型不再出现在业务代码中。

## API 映射

| 旧思路 | 新 API |
| --- | --- |
| Coach mark controller | `PTInstructionCenter.shared` |
| Coach mark target view | `PTInstructionTarget.view(_:)` |
| 动态复用目标 | `pt_registerInstructionTarget` |
| 文本内容 | `PTInstructionContent.message` |
| 自定义 UIView | `PTInstructionContent.view` |
| 完成/跳过结果 | `PTInstructionResult` |

所有调用放在可见的 `@MainActor UIViewController` 中；目标未进入 Window 时使用 `targetWaitPolicy: .wait(seconds:)` 或 `.skip`。
