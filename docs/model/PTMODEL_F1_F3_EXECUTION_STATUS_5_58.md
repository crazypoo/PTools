# PTModel 5.58.0 — F1 / F2 / F3 执行状态

## 范围

本次只关闭 F1、F2、F3。F4 的真实项目、真机、TSan、RSS、跨平台、Archive
和第三方 differential 验证由真实宿主项目继续执行，不在本地 Core 结果中冒充完成。

## F1：Semantics / Macro / Inheritance

- ✅ 全局、模型、父类 key policy 已进入 `PTModelDecoder` / `PTModelEncoder`，并有优先级 golden。
- ✅ discriminator → concrete static model 已由 `PTModelDynamicResolver` 统一入口处理。
- ✅ Int、UInt64、2^53 安全整数和资源限制的 exact / +1 corpus 已覆盖。
- ✅ 字段描述器新增字段保持旧 JSON payload 可读取。
- ✅ `@PTModel` wrapper、组合 wrapper、CodingKeys、Path、Flat、默认值和 public metadata 有独立 golden。
- ✅ 三层 `@PTSubclass` 字段合并、稳定顺序、继承标记和 direct path 有独立 golden。
- ✅ `PTPolymorphic` / `PTExtras` 的 Schema 标记有独立 golden；Observation 与 ObjC 运行时存储不由宏猜测，使用明确兼容边界。
- ✅ `@Observable` 类型会得到确定性宏诊断；`@objc dynamic` 字段不会进入无反射 direct path。
- ✅ lifecycle 的值型 hook 顺序与 Codable / direct 入口保持一致；继承类不隐式猜测父类静态 hook，需显式在业务 hook 中串联。

## F2：Direct Fast Path / Runtime

- ✅ alias、Path、Flat、nested primitive/collection、Transform、Validate 已走扫描或归一化后的 direct construction，并保留错误回退。
- ✅ session/context、duplicate-key、limits、numeric overflow 和 diagnostics 不因 direct path 丢失。
- ✅ Polymorphic 使用 typed registry/resolver；Extras 使用显式 `decodeWithExtras`，两者不会把 `Any` 或可变全局状态带入 Core。
- ✅ streaming encoder 在成功、取消、部分写入失败时都会调用 `finish()`；actor sink 具备字节上限。
- ✅ 100,000 项 AsyncSequence 只通过逐项编码写入 Sink，测试不创建完整输入数组，也不在 Core 构造完整数组 Data。
- ✅ File sink 的 flush/close 错误沿 async sink 抛出；默认 Data sink 仍明确是“返回完整 Data”的便捷 API，不宣称无界内存。
- ✅ 复杂 annotation / extras 的 schema fallback 已写入兼容矩阵，属于明确的 correctness boundary，不是隐式回退。

## F3：Legacy Network / Consumer

- ✅ 旧 `requestApi` 参数编码、`nil modelType`、body、upload、response parser 和取消路径已添加 URLProtocol 兼容夹具。
- ✅ Codable parser 与 legacy parser 对同一 `PTNetworkResponseSnapshot` 的结果契约有并行断言。
- ✅ 旧 transport seam 保持 internal，仅供 iOS 兼容测试验证，不扩大公开 API。
- ✅ SwiftPM 的 legacy SmartCodable、KakaJSON、Mixed 和 PTModel-only consumer fixture 保留。
- ✅ CocoaPods `PooTools/Model` consumer 已补齐 Podfile、Consumer.swift 和安装说明；legacy codec 仍为显式 opt-in。
- ✅ `PToolsNetworkTests` 已使用 iOS 17 Simulator SDK / arm64 编译，覆盖旧 Network 兼容夹具的真实模块边界。
- ✅ `internalSmartCodableImports = 0`、`internalKakaJSONImports = 0`、`remainingLegacyNetworkCalls = 0` 继续作为门禁。

## 可复现验证

```text
bash Scripts/PTModel/validate_f1_f3.sh
```

该脚本使用 `find`/`grep`，不依赖 `rg`。模型 Core / Macro tests 在 Foundation-only
环境运行；Network URLProtocol 夹具会在 iOS 17 Simulator SDK 下编译，CocoaPods consumer
通过 iOS workspace 构建验证。F4 的真实项目验证保持待办。
