# PhotoPicker 5.69.0 迁移指南

## 变更摘要

5.69.0 对 PhotoPicker 做职责收敛和稳定性修复，公开入口保持兼容：

- `PTMediaLibViewController` 仍是多媒体选择页面入口。
- `PTMediaLibManager`、`PTMediaLibConfig.share`、`PTMediaModel`、`PTResultModel` 和旧回调继续可用。
- 选择状态现在由当前 Picker 实例独立维护，切换相册不会丢失已经选择的媒体。
- iCloud 下载、PhotoKit 请求和提交任务支持真正取消；关闭页面后不会继续回写 UI。
- 编辑视频成功后会按替换语义更新原选中项，并保持用户选择顺序。
- 相机照片/视频结果会先在 delegate 边界完成类型化解析；视频先复制到框架自有的临时文件，再交给 PhotoKit 保存，保存结束后清理该副本。
- 空选择、取消、权限失败、保存失败和 PhotoKit 迟到回调不会触发图片识别、视频编辑或重复完成回调。

## 5.69.0 性能与刷新边界

增补审计后，PhotoPicker 的 PhotoKit 变化统一由当前 Picker 实例的 `PTMediaAlbumRepository` 接收。截图、前台恢复、拍摄保存和编辑替换只发送刷新意图；相同相册、相同内容版本不会再次清空网格或提交完整列表。真实结构变化会优先使用 `PTCollectionView` 的局部插入、删除和内容更新，只有相册切换或无法安全表达的较大变化才使用完整快照替换。

相册模型会按资源标识和 PhotoKit 元数据复用未变化的 `PTMediaModel`。Cell 会等待实际布局尺寸稳定后请求缩略图，复用时取消旧请求；单纯选中图片不会自动下载原图。拍照图片编码和录像临时文件复制在保留公开 API 的前提下移出 UI 关键路径。

### P01–P06 增补：拍照刷新、Grid 状态和实例级反馈

本轮继续复用 `PTMediaAlbumRepository`、`PTMediaSelectionStore` 和 `PTCollectionView`，没有新增第二套 PhotoKit 快照或 Diffable DataSource：

- PhotoKit 事务只为新增或元数据变化的资源创建新的 `PTMediaModel`，未变化资源按 `localIdentifier` 复用；Row 的真实提交状态与最新期望状态分开记录。
- 网格结构提交完成前不会把排队数据当作已显示数据；无变化提交、迟到 completion、相册切换和窗口关闭都会进入有限终态。
- Cell 复用时先展示占位图，PhotoKit 返回 nil、错误或取消时保留已有成功图片；请求诊断只记录状态、尺寸、请求号和耗时，不记录媒体内容或原始资产标识。
- 拍照后的新资源以 `assetID + capture token` 等待真实进入当前相册；等待有界，超时会清理，不会凭空插入不存在的 IndexPath。

需要自定义反馈时，在每个 Picker 实例上设置 `onFeedback`，不要修改全局单例：

```swift
let picker = PTMediaLibViewController()
picker.selectionOptions = .multipleImage
picker.onFeedback = { feedback in
    switch feedback.kind {
    case .saveStarted:
        hostHUD.start(identifier: feedback.operationID)
    case .saveSucceeded, .saveFailed, .saveCancelled:
        hostHUD.finish(identifier: feedback.operationID)
    default:
        hostToast.show(feedback.message)
    }
}
picker.mediaLibShow()
```

`onFeedback == nil` 时继续使用原有 `PTAlertTipsViewController.tipsAlertShow`；配置非空后，受控的内部提示只发送 `PTMediaPickerFeedback`，由宿主自行决定显示、记录或忽略。系统的相机/照片权限对话框不被拦截。保存事件使用同一个 `operationID`，终态只发送一次。PhotoPicker Demo 现在提供 Default Tips 与 Custom Feedback 两个入口，可直接对照验证。

`PTMediaLibView` 内部已使用 `cellInCollectionV2` 和 `configureCell`，外部不需要创建第二个数据源，也不需要直接操作内部 Cell。旧的公开选择、保存和回调入口仍保留。

### 选择状态与拍照刷新一致性

选择状态的唯一来源是当前 Picker 实例的 `PTMediaSelectionStore`。Cell 只使用资源 `localIdentifier` 投影按钮选中状态、选择序号、遮罩、边框和编辑入口；未选资源不显示 `0`。Cell 复用、相册切换、缩略图完成回调和拍照自动选中都必须重新按资源 ID 投影，不能用旧 `IndexPath` 或 `PTMediaModel.isSelected` 作为判断来源。

PhotoKit 通知会先形成带相册标识、generation、revision 和资源 ID 差异的内部事务。已有相册不会因为拍照而先退回首批模型；无法安全增量表达时，会保留当前列表并在完整快照准备好后一次提交。拍照保存成功后的自动选中复用同一个 Store reservation，重复通知或重复资源只会产生一次选择结果。

诊断阶段使用 `OSLog` 记录刷新来源、模型构建耗时、局部/完整行更新和相机保存阶段，只记录计数、标识存在性和耗时，不记录图片、视频字节或用户文件名。生产环境仍应由宿主控制日志级别。

### 首次打开卡顿专项

5.69.0 继续复用同一套 `PTMediaPickerTrace`，并为 `viewDidLoad`、相机胶卷加载和模型批次增加 signpost 区间。首次相册只先构建有限数量的可见候选，后续按有界批次追加；每个批次之间让出 MainActor，页面关闭或切换相册时会取消过期 generation。这个实现不会改变选择顺序、过滤条件或相机 Cell 的位置。

PhotoKit 刷新先比较结果数量以及首尾资源的稳定元数据。无变化的通知不会重建模型或提交列表；首尾不变但可能存在中间资源变化时，才使用一次可追踪的完整快照 fallback。`PTMediaLibListModel` 在确认模型指纹不变时也会更新已建模标记，避免下一次重复扫描。

多行增删和重排使用 `PTCollectionView.replaceRows`，保留相册 Section 身份并恢复首个可见资源的相对位置。设置视频大小限制时，内部在最终选中前使用公开且可取消的 `PHAssetResourceManager` 统计资源大小，单位与旧 `KBUnit` 兼容；无法取得大小会拒绝本次受限选择，而不是把未知值当作通过。

这批源码已通过 Swift 前端解析和 `PooTools.xcworkspace` 的 iOS Simulator Debug/Release 完整构建。真机首帧 p95、Hangs、Instruments、10,000 资源量级、相机/视频拍摄和符号化崩溃闭环仍属于宿主验收，不把模拟器构建当作这些运行时结论。

## 原有调用方式继续可用

```swift
let picker = PTMediaLibViewController()
picker.selectionOptions = .singleImage
picker.selectedHudStatusBlock = { isLoading in
    // 更新宿主页面的加载状态
}
picker.selectImageBlock = { results, isOriginal in
    // 继续使用原有结果回调
}
picker.selectImageRequestErrorBlock = { assets, failedIndices in
    // 继续使用原有失败回调
}
picker.onFinish = { outcome in
    // 可选类型化入口：items 与 failedAssetIndices 属于同一次完成事件
    // El callback tipado es opcional y pertenece al mismo evento terminal.
    // The typed callback is optional and belongs to the same terminal event.
    print(outcome.items.count, outcome.failedAssetIndices)
}
picker.mediaLibShow()
```

如果同时设置 `onFinish` 和历史回调，内部只执行一次提交；先分发历史成功/失败回调，再分发一次 `onFinish`，不要在两个入口重复上传结果。
用户主动关闭 Picker 仍保持旧行为，只有点击完成并进入提交终态时才触发类型化完成事件。

旧项目也可以继续在展示前配置兼容单例：

```swift
PTMediaLibConfig.share.maxSelectCount = 9
let picker = PTMediaLibViewController()
picker.selectionOptions = .multipleImage
picker.mediaLibShow()
```

新的业务代码应优先给每个 Picker 实例设置 `selectionOptions`，避免多个页面共享可变单例导致配置串扰。

## 选择规则

5.69.0 将图片/视频混选校验统一为双向规则。`allowMixSelect == false` 时，先选图片再选视频、
或先选视频再选图片都会被拒绝；异步 iCloud 下载期间会先预留选择名额，下载结束后再次校验，重复点击不会重复加入。

GIF、Live Photo、普通图片属于同一图片族，只有图片族与视频族之间受 `allowMixSelect` 限制；GIF/Live Photo 过滤、
视频数量、视频时长和文件大小仍遵循 `PTMediaLibSelectionOptions` 的既有配置，
没有把旧配置语义迁移到新的全局状态。

## 取消和生命周期

页面退出、用户取消或提交完成时，内部会取消未完成的 PhotoKit 请求，并注销相册变更观察者；取消与超时不会混淆为同一种错误。宿主仍只需要
按照原回调处理结果，不要在回调之外继续持有 Picker 的内部 View 或 Cell。

## 相机和真机验证边界

本次源码已对拍照/录像完成后的空结果、保存失败、视频临时文件生命周期、PhotoKit 任意队列通知和重复 dismiss 做静态防护，
并通过 CocoaPods workspace 的 iOS Simulator Debug 构建。真机相机连续拍摄、权限变化、相册实际变更、iPhone Duo 展开/折叠和 Instruments
仍必须在真实设备上执行；没有 `.ips` 或符号化调用栈时，不应把静态防护写成已证明的崩溃根因修复。

Release 构建和完整测试矩阵仍需结合宿主的签名、相册规模、iCloud 状态和真实设备执行；本指南不会把模拟器构建报告写成真机性能通过。

## Core 复用与平台边界

PhotoPicker 继续复用 PTools Core 的 `PTMediaRequestCoordinator`、`PTMediaSaveService`、`PTMediaCache`、
`PTImageDownsampler` 和 `PTCollectionView`，不需要额外安装新的第三方依赖。`PooToolsImageEditor` 仍然
依赖 PhotoPicker，PhotoPicker 不反向依赖 ImageEditor。

该页面基于 UIKit 和 PhotoKit，5.69.0 的 PhotoPicker UI 支持 iOS/iPadOS 17+。watchOS、visionOS、macOS
不宣称直接支持该 UIKit 页面；这些平台可以继续使用适用的 Core/值类型能力，具体 UI 由宿主平台适配。

## 验证建议

请在真实宿主中覆盖：单选、多选、图片/视频混选、GIF、Live Photo、iCloud 资源、相机回传、编辑视频替换、
权限拒绝/有限照片权限、快速重复点击、快速退出和 iPhone Duo 窗口尺寸变化。
