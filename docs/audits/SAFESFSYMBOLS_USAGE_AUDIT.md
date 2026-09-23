# SafeSFSymbols 使用审计

## 结论

5.24.0 已从生产源码、SwiftPM、CocoaPods 和锁文件移除 SafeSFSymbols。当前唯一的符号实现入口是
`PToolsSymbols`，历史名称只允许出现在本审计、迁移说明和第三方通知中。

## 迁移范围

| 范围 | 结果 |
| --- | --- |
| `PooToolsSource` / `PooTools` / `Tests` 导入 | 已迁移到 `PToolsSymbols` 或显式动态解析 |
| SwiftPM | 删除 SafeSFSymbols package，新增 `PToolsSymbols` product/target |
| CocoaPods | 删除 SafeSFSymbols dependency，新增 `Symbols` subspec |
| `Package.resolved` / `Podfile.lock` | 删除 SafeSFSymbols 锁定记录 |
| 静态 `UIImage(systemName:)` | 迁移到类型化入口；动态解析保留白名单 |
| 第三方源码 | 未修改、未复制、未重新分发 |

## 允许的动态路径

服务端返回的名称、配置拼接名称、新系统符号和兼容层不能在编译期全部枚举，因此由
`PTSymbol(rawValue:)` 和 `PTSymbolResolver` 处理。解析顺序是主名称、目录别名、显式回退，失败时
返回 `nil` 并记录调试诊断；生产环境不崩溃。

## 门禁

```text
bash Scripts/Symbols/verify-generated-symbols.sh
bash Scripts/validate_symbols_5_24.sh
```

新增静态符号调用、SafeSFSymbols 活动依赖或 `PToolsSymbols` 内的符号强制解包都会使门禁失败。
