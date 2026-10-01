# PTModel 5.58.0：R1–R3 执行状态

> 本文对应 `/Users/jax/Downloads/PTools_5.58.0_PTModel_Remaining_13_Percent_To_100_Plan.md`。
> 本次只关闭 R1、R2、R3；R4 的真实项目、TSan、真机和多平台验证由业务项目继续执行。

## 结论

| 路线 | 状态 | 关闭方式 |
| --- | --- | --- |
| R1 Semantics / Feature Parity | ✅ 完成 | 统一字段决策、Presence、默认值、转换/校验、动态解析、Extras、Patch 与回归矩阵 |
| R2 Macro / Inheritance / Direct Fast Path | ✅ 完成 | `@PTModel`、`@PTSubclass`、N 级父类 Schema 合并、原始 Data slice 和 Foundation 直接 codec |
| R3 Network / Migration / Dependency Split | ✅ 完成 | Core 依赖审计为 0、旧 API 兼容包装器保留、SwiftPM/CocoaPods Consumer fixture 建立并编译 |
| R4 Quality / Performance / Release | ⏸ 待真实项目 | 不用静态检查替代 TSan、差分、Fuzz、真机和发布验证 |

## R1：语义收口

- ✅ `PTModelFieldDecision.resolve` 同时服务 Presence、missing/null/invalid/overflow、required、default 和 encoder nil 策略；Schema 与 StaticCodec 不再各自维护一套判定。
- ✅ Optional、non-Optional、`PTPresence`、`PTRequired`、默认值和数值溢出矩阵已纳入 `PTModelCoreTests`。
- ✅ `PTStaticSchemaPrecedence` 明确为 `.staticBeforeCodable` / `.codableOnly`；自定义 `Codable` 仍是兼容逃生口。
- ✅ alias、typed path、Flat、前缀相似 key、Stringified、Lossy、数组/字典/Set、Date/Data/URL 和完整转义回归已覆盖。
- ✅ `PTModelAnnotationProvider` 统一 `PTTransform` / `PTValidate` 的 decode 与 encode 阶段；宏生成的 Schema 会应用注解，Direct Path 对需要注解的模型自动关闭，避免语义绕过。
- ✅ `PTAssociatedEnumTransformer`、`PTModelTypeResolver`、`PTModelDefaultMerge`、`PTModelUpdater` 和 `PTModelPatch.fromPresence` 提供类型化双向边界。
- ✅ property observer 仅接受存储属性上的 `willSet` / `didSet`，计算属性和 getter-only 属性在宏展开期明确报错；观察副作用只在正常模型赋值时触发。

## R2：宏、继承和 Direct Path

- ✅ `@PTModel` 支持稳定字段 descriptor、CodingKeys、Key/Path/Required/Flat/Ignore、Default、Lossy、Stringified、泛型字段和 property-wrapper 的 wrapped value。
- ✅ `@PTSubclass` 支持父类 Schema 查找、N 级字段合并、继承 mapping/default、重复字段与 encode-key 冲突报告、父类字段应用和父类字段编码。
- ✅ 根类显式声明 `PTStaticClassModel`，子类通过 `@PTSubclass` 复用继承的类型契约；这是 Swift 6 宏系统避免重复 conformance 的稳定写法，已由三层 class fixture 覆盖。
- ✅ final class、不可变 `let` 字段和自定义 `Codable` 自动退出类 Direct Construction，使用安全 Codable fallback，不伪造空初始化器。
- ✅ public/open 访问级别按宿主声明传播；generic type reference 使用参数名而不是重复约束；NSObject/ObjC-compatible stored fields 不进入额外的运行时反射路径。
- ✅ Direct Path 顺序固定为 `scanner → field slice → Foundation codec → model`；普通 primitive、精确 Int/UInt、Decimal、Date/Data/URL、嵌套 PTModel、数组/字典/Set 和 Lossy array 均可使用原始 Data slice。
- ✅ `PTJSONScanner.collectArrayElementSlices` 和 `PTModelDecoder.decodeRawArray/decodeRawOptionalArray` 共享资源限制、边界检查和 Lossy 策略，不重新构建完整 PTJSONValue 数组。
- ✅ Path、Flat、Transform、Validate、Polymorphic、Extras 和 lifecycle 模型按语义自动回到规范 Schema/Codable 路径；这是 intentional fallback，不会为了“Direct”跳过语义。
- ✅ lifecycle 在直接路径前后保持一致；带 lifecycle 的模型不会提前返回未触发 hook 的对象。

## R3：Network、迁移与依赖切分

- ✅ `requestPTModel` / `PTNetworkResponseDecoder.ptModel` 是新类型化入口；旧 `requestApi`、`requestBodyAPI`、上传和 KakaJSON/Any decoder 保留在 deprecated 兼容边界。
- ✅ `Network.swift` 的内部请求执行器不直接导入 SmartCodable/KakaJSON；旧 codec 只由 `PToolsModelLegacySmartCodable`、`PToolsModelLegacyKakaJSON` adapter 提供。
- ✅ `Scripts/PTModel/audit_model_dependencies.swift` 当前硬门禁：

```text
internalSmartCodableImports = 0
internalKakaJSONImports = 0
remainingLegacyNetworkCalls = 0
```

- ✅ Consumer fixture：`SmartCodableLegacyApp`、`KakaJSONLegacyApp`、`MixedLegacyApp`、`PTModelOnlyApp`、SwiftPM wiring、CocoaPods wiring。
- ✅ SwiftPM 为四类 Consumer 建立独立 executable target；旧适配器不再把 UIKit/full `ptools` 传递给 KakaJSON adapter target。
- ✅ CocoaPods 的 `ModelCore` / `Model` 不依赖第三方 codec；legacy subspec 继续 opt-in，保持旧项目迁移窗口。

## 已验证证据

- ✅ `swift package dump-package`
- ✅ `swift build --target PToolsModel`
- ✅ `swift build --target PToolsModelTests`
- ✅ `PToolsModelTests.xctest`：30 tests，0 failures
- ✅ `swift build --target PToolsModelLegacySmartCodable`
- ✅ `swift build --target PToolsModelLegacyKakaJSON`
- ✅ `swift build --target PTModelLegacySmartCodableFixture`
- ✅ `swift build --target PTModelLegacyKakaJSONFixture`
- ✅ `swift build --target PTModelMixedLegacyFixture`
- ✅ `swift build --target PTModelOnlyFixture`
- ✅ `bash Scripts/PTModel/validate_65_to_100.sh`
- ✅ `git diff --check`
- ✅ iOS workspace `PooTools` Debug Simulator 构建通过。
- ✅ iOS workspace `PooTools-Example` Debug / Release Simulator 构建通过；构建期间的 Pods 脚本警告未被计入 PTools 源码失败。

## R4 边界

R4 不在本次自动关闭范围内：真实项目仍需执行 TSan 1000-task、第三方 differential、property/fuzz、真机 allocation/RSS、Release 真机 benchmark、多平台 Archive 和真实旧项目运行回归。它们不会被本地模型单元测试或 Simulator 构建替代。

## 版本与发布

- 当前 `VERSION` 保持 `5.58.0`。
- 本次不创建 tag；R4 完成后再由发布流程决定 tag 和 release。
