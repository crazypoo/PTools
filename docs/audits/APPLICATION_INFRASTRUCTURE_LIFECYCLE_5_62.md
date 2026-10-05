# PTools 5.62 Application Infrastructure Lifecycle Audit

## 生命周期控制

- `PTTransferQueue`、`PTSyncEngine`、`PTRealtimeClient`、`PTTransactionMonitor` 和 WebBridge 都提供显式停止或取消边界。
- Demo 控制器在离开页面时取消任务，不把异步结果回写到已离屏页面。
- `PTWebBridge.invalidate()` 移除 message handler、清空 handler 表并释放 WebView 引用。
- StoreKit monitor 重复 start 幂等，并按交易 ID 去重。
- Realtime SSE 记录 Last-Event-ID，支持服务端 `retry:`、指数退避和重连上限。

## 待宿主验证

- 后台 URLSession relaunch、系统交付 delegate 和 AppDelegate 生命周期需要真实 iOS 宿主验证。
- BackgroundTasks、网络切换、前后台切换、内存警告和进程终止后的恢复需要真机证据。
- WebView 多实例、导航退出和宿主释放顺序需要 Xcode UI 场景验证。

## 结论

代码侧生命周期入口已统一，iOS Simulator Debug / Release 构建通过；平台回调和进程级恢复仍标记为 pending，不把静态构建结果当成运行时闭环。
