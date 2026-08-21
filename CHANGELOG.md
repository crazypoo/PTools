# Changelog

## 4.5.19 - 2026-08-21

- 修正 Xcode 警告门禁，按各 target 自身配置构建，并区分 PooTools 源码、Pods 和工程环境诊断。
- 修复二维码图片识别、相机 metadata 转换、导航生命周期日志和无活动窗口场景中的崩溃风险。
- 移除屏幕圆角私有 KVC，改用活动窗口公开的 safe-area 信息。
- 优化 `PTCollectionView` 骨架路径缓存、离屏动画暂停和 Reduce Motion 动态切换。

## 4.5.18 - 2026-08-21

- 为 `PTCollectionView` 增加独立覆盖层骨架，支持现有布局模式、深色模式和 Reduce Motion。
- 骨架显示不修改 Diffable snapshot，也不触发业务 Cell 注册或数据回调。

## 4.5.17 - 2026-08-21

- 统一 PhotoPicker、MediaViewer 和 VideoEditor 的媒体保存服务到 Core 模块。
- 统一 PhotoKit Cell 请求取消、资源标识校验和复用 generation，避免旧请求回写新 Cell。
- 统一图片加载配置、视频首帧生成、Router VC 解析和 Network 请求上下文。
- 收敛权限请求 completion 的 MainActor 桥接，移除通知权限状态读取的数据竞争。
- 增加重复入口清单脚本，并保留旧公开入口作为兼容包装器。
- Xcode 完整警告验收记录了外部 Pods 的 Swift 6 并发阻断，并已按仓库格式创建 `4.5.17` tag。

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
