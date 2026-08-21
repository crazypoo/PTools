# Changelog

## 4.5.16 - 2026-08-21

- 增加 PooTools 源码 Xcode warning 门禁，并区分源码问题与外部 Pods 环境阻断。
- 统一媒体保存兼容入口到 `PTMediaSaveService`，补齐权限、编码、保存和资源回读失败结果。
- 修复联系人保存失败误报成功、联系人分组复用模型，以及 PhotoPicker 和视频编辑器的高风险隐式解包。
- 稳定 Network 请求去重摘要，Release 默认不输出请求参数和完整响应体。
- 收敛 Swift 6 的 `@unchecked Sendable` 登记与主线程 completion 边界。

## 4.5.15 - 2026-08-20

- 继续完善 iOS 17 / Swift 6 构建契约和媒体请求并发边界。

## 4.5.14 - 2026-08-20

- 修复 Router 非法类名、非法参数和路由重定向配置导致的强制崩溃。
- 收敛 PhotoPicker、相机和图片请求的 PhotoKit 线程边界，统一取消、降级和失败结果。
- 修复联系人、检查更新、分享、调试设置和视频编辑器的核心强制解包。
- 统一 Network 普通参数和 Body 请求的插件、缓存、去重、取消和错误执行管线。
- 统一 iOS 17 系统空状态的 loading、empty、error、content 状态渲染，避免重复叠加。
- 继续保持 iOS 17.0+ / Swift 6.0 三套构建入口契约。

## 4.5.13 - 2026-08-20

- 统一 Swift 6 / iOS 17.0+ 构建契约。
- 改进 PhotoPicker、VideoEditor 和网络层的并发边界与失败回调。
- 增加构建入口质量校验和发布流程文档。

## Unreleased

记录下一版本的用户可见变化、兼容性变化和修复内容。
