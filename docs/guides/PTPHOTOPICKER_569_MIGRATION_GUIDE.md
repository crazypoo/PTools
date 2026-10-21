# PhotoPicker 5.69.0 迁移指南

## 变更摘要

5.69.0 对 PhotoPicker 做职责收敛和稳定性修复，公开入口保持兼容：

- `PTMediaLibViewController` 仍是多媒体选择页面入口。
- `PTMediaLibManager`、`PTMediaLibConfig.share`、`PTMediaModel`、`PTResultModel` 和旧回调继续可用。
- 选择状态现在由当前 Picker 实例独立维护，切换相册不会丢失已经选择的媒体。
- iCloud 下载、PhotoKit 请求和提交任务支持真正取消；关闭页面后不会继续回写 UI。
- 编辑视频成功后会按替换语义更新原选中项，并保持用户选择顺序。

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

GIF、Live Photo、普通图片、视频数量、视频时长和文件大小仍遵循 `PTMediaLibSelectionOptions` 的既有配置，
没有把旧配置语义迁移到新的全局状态。

## 取消和生命周期

页面退出、用户取消或提交完成时，内部会取消未完成的 PhotoKit 请求，并注销相册变更观察者。宿主仍只需要
按照原回调处理结果，不要在回调之外继续持有 Picker 的内部 View 或 Cell。

## Core 复用与平台边界

PhotoPicker 继续复用 PTools Core 的 `PTMediaRequestCoordinator`、`PTMediaSaveService`、`PTMediaCache`、
`PTImageDownsampler` 和 `PTCollectionView`，不需要额外安装新的第三方依赖。`PooToolsImageEditor` 仍然
依赖 PhotoPicker，PhotoPicker 不反向依赖 ImageEditor。

该页面基于 UIKit 和 PhotoKit，5.69.0 的 PhotoPicker UI 支持 iOS/iPadOS 17+。watchOS、visionOS、macOS
不宣称直接支持该 UIKit 页面；这些平台可以继续使用适用的 Core/值类型能力，具体 UI 由宿主平台适配。

## 验证建议

请在真实宿主中覆盖：单选、多选、图片/视频混选、GIF、Live Photo、iCloud 资源、相机回传、编辑视频替换、
权限拒绝/有限照片权限、快速重复点击、快速退出和 iPhone Duo 窗口尺寸变化。
