# PTools 5.67.x 功能所有权矩阵 / Function Ownership Matrix / Matriz de propiedad

> 基线审计台账，不是发布通过证明。Baseline audit ledger, not release proof. Registro de auditoría base, no prueba de lanzamiento.

- `sourceRevision`: `b5898d124c409bcf25ba824e40cdd616cf9284df`
- `version`: `5.67.2`
- `auditDate`: `2026-10-19`
- `status`: `baseline_only`

| Feature | Capability | Owner / 唯一实现候选 / Propietario | Primary entry | Legacy/adapters | Kind | Status | Decision / blocked reason |
|---|---|---|---|---|---|---|---|
| FD-01 | SnapKit helpers | PToolsUIFoundation | UIFoundation helper | Base/PTSnapKitEX thin bridge | D1/D6 | migrated | SPM/Pods 编译已接通；符号/API 对比与布局时序回归仍待完成 |
| FD-02 | Download/transfer | PToolsTransferCore + PToolsTransfer | PTTransferFileDownloadService foreground executor | Network, audio, video, PTTransferQueue background adapter, Live Photo | D2 | migrated | 前台文件下载、音频、视频和 TransferQueue foreground 已接通；后台 delegate 与 Live Photo 保持专用适配，行为矩阵和真实网络回归仍待完成 |
| FD-03 | Segment | SegmentControl/PTSegmentedView | PTSegmentedView | PTSegmentView | D3 | confirmed | 先补齐旧属性和回调时序映射 |
| FD-04 | Speech recognition | recognition session core | PTSpeechRecognitionSession (planned) | PTSpeech, OSSSpeech | D2 | confirmed | 录音/TTS 保留，需真机生命周期证据 |
| FD-05 | Video export | shared lifecycle only | export lifecycle executor (planned) | PTVideoExportService, C7, Exporter | D2/D4 | confirmed | composition/filter/ReaderWriter 不合并 |
| FD-06 | Overlay/HUD | PTOverlayCore for host lifecycle | PTOverlayCore | PTHudView, PTProgressHUD, Tips | D4 | confirmed | 视觉和 modal/progress 语义保留 |
| FD-07 | Media cache | PTMediaCache policy | PTMediaCache | audio/video/file/image layers | D4 | confirmed | 统一 key/TTL/metrics，不合并存储层 |
| FD-08 | Content state | PTContentState | state priority model | EmptyDataSet, CollectionView, Skeleton | D4 | confirmed | 需完整状态转换回归 |
| FD-09 | PDF | shared utilities only | separate generation/render/preview contracts | PDF helpers/documents | D4 | confirmed | 无 golden fixture，不做破坏性合并 |
| FD-10 | Permission distribution | PToolsPermissionCore + facade | Foundation permission contract | PermissionCore/PTPermission | D6 | migrated | SwiftPM uses the standalone target; CocoaPods embeds the same source once in its aggregate target; runtime parity remains pending |
| FD-11 | Logging | PToolsLogging/PTLogger | PTLogger | PTNSLog | D5/D6 | rejected | 已有转发，做守护，不重复实现 |
| FD-12 | Haptics | PTFeedbackCenter | PTFeedbackCenter | legacy control/category | D5 | rejected | 已统一事件分发 |
| FD-13 | WebSocket | PTWebSocketClient | PTWebSocketClient | PTSocketManager | D5 | rejected | 已有 facade，SSE 保持不同协议 |
| FD-14 | Banner | PTBannerView | PTBannerView | PTCycleScrollView | D5 | rejected | 已由继承关系复用 |
| FD-15 | Search | composed controller/view | PTSearchViewController + PTSearchBar | none | D5 | rejected | 正常组合，不是重复实现 |
| FD-16 | Navigation/button/image | pending audit | pending | pending | candidate | candidate | 禁止凭名称合并，先做调用图和平台审计 |

## 规则 / Rules / Reglas

1. `owner` 是执行真源；旧入口只能做参数、回调或类型适配。
2. 未通过 SPM、CocoaPods 和运行时回归的迁移不得标记 `migrated` 或 `verified`。
3. UI、Foundation、媒体渲染和协议不同的语义不能为了减少文件数强行合并。
4. iOS 之外的平台只纳入其可编译的 Foundation/Core 层；UIKit 专属实现必须显式标记边界。
