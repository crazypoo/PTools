# Gesture Policy

## 方向解析

`PTGestureDirectionResolver` 根据速度比例把手势分为 horizontal、vertical 或 undetermined。阈值默认大于 1，避免接近对角线的手势被错误抢占。

## 手势仲裁

`PTGestureArena` 只提供轻量策略，不依赖私有 API 或第三方分页手势。系统返回手势仍由 `UINavigationController.interactivePopGestureRecognizer` 所属导航控制器管理，`PTNavigationGestureAdapter` 只判断当前栈和页面索引是否允许开始。

## 建议

- 横向分页只在水平速度明确时处理。
- 垂直 Nested Scroll 优先交给当前 ScrollView。
- 第一个页面的边缘返回手势由宿主导航控制器决定。
- 不要通过全局单例修改所有导航控制器的手势代理。
- Header 中有横向控件时，明确它与外层纵向滚动的同时识别策略。

所有 UIKit 手势对象都在 MainActor 内使用；不要把手势 recognizer 或 View 跨 actor 传递。
