# Third-party notices

## SwifterSwift

PTools 5.23.0 的迁移工作参考了 SwifterSwift 的公开 API 组织方式和边界行为，但未复制其源码实现。PTools 使用独立实现替换实际调用点，并通过自己的行为验证和 Swift 6 / iOS 17 构建门禁。

SwifterSwift is distributed under the MIT License. Its historical repository remains available at <https://github.com/SwifterSwift/SwifterSwift>. PTools does not ship the dependency after the 5.23.0 removal.
