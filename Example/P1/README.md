# P1 宿主回归示例

P1 的 Provider 合同由生产模块定义，模拟模块只提供替身：

- `PTConnectivityProviding`：测试断网、恢复和内容状态切换。
- `PTBluetoothProviding`：测试扫描、连接和通知状态，不替代真实 BLE 回归。
- `PTLocationProviding`、`PTDeviceCapabilityProviding`：测试权限和设备能力分支。
- `PTDocumentPDFBridge`：只将 PDF 交给 Quick Look 或 PDFKit，其他文件继续走文档入口。

表单页面直接使用 `PTFormViewController` 的 `PTCollectionView`，字段 ID 必须稳定；生产宿主还
需要覆盖 VoiceOver、Dynamic Type、RTL、Reduce Motion、键盘遍历和多 Scene。
