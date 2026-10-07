<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_sendable_exceptions.rb
Source revision: e56b376ef91456b11a81d1082765dcb5c0a2bdeb
Generated at: 2026-10-07T15:11:47Z
-->

# Swift 6 Sendable 例外清单

本文件由 `Scripts/report_sendable_exceptions.rb` 生成；它只记录现状，不把 `@unchecked Sendable` 视为无条件安全。

| 类型/声明位置 | 行号 | 声明 | 白名单 | 处理原则 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/C7Collector/C7CollectorCamera.swift` | 17 | `private struct PTSystemPixelBufferBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/C7Collector/PTC7VideoExportService.swift` | 13 | `private struct PTC7FilterBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/C7Collector/PTC7VideoExportService.swift` | 17 | `private final class PTC7VideoCompositionInstruction: AVMutableVideoCompositionInstruction, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/C7Collector/PTC7VideoExportService.swift` | 42 | `private final class PTC7VideoFilterCompositor: NSObject, AVVideoCompositing, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 15 | `private struct PTSendableEventStoreBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 19 | `public struct PTSendableEventArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 27 | `public struct PTSendableReminderArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/AVExport+PTEX.swift` | 13 | `public struct PTAssetExportResult: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 21 | `public struct PTSendableAVAsset: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 45 | `private struct PTSendableExportSession: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 37 | `private struct PTVideoAssetSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Core/OSSVoice.swift` | 162 | `public class OSSVoice: AVSpeechSynthesisVoice, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 13 | `private struct PTSafeExceptionBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 17 | `private struct PTSafeSignalPointerBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift` | 26 | `final class PTCustomHTTPProtocol: URLProtocol, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/HeartRate/PTHeartRateViewController.swift` | 17 | `private struct PTHeartRateSampleBufferBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Inspector/MainThreadAsyncOperation.swift` | 12 | `final class MainThreadAsyncOperation: MainThreadOperation, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Inspector/MainThreadOperation.swift` | 12 | `class MainThreadOperation: Operation, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 17 | `private final class AVContext: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 37 | `private struct PTAVSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 44 | `private final class ProgressState: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/MXMetricKitManager/MetricsManager.swift` | 13 | `public final class MetricsManager: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Motion/PTMotion.swift` | 81 | `public class PTMotion: NSObject, @unchecked Sendable,CMHeadphoneMotionManagerDelegate {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 14 | `private struct PTNFCSessionAndTagSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 19 | `private struct PTNFCSessionSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 23 | `private struct PTNFCSessionAndNDEFSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network+LegacyCompatibility.swift` | 18 | `private struct PTLegacyModelTypeBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 153 | `public final class Network: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 22 | `public final class NetworkReachability: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 61 | `public final class PTNetWorkStatus: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 129 | `public class OSSSpeech: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 385 | `final class ConverterState: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSUtterance.swift` | 27 | `public class OSSUtterance: AVSpeechUtterance, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsActivities/PTActivities.swift` | 88 | `private final class PTActivityKitSendableBox<Value>: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsDatabase/PTDatabase.swift` | 39 | `private final class PTSQLiteHandle: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPServer.swift` | 68 | `private final class PTHTTPNetworkConnectionTransport: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPTypes.swift` | 300 | `public struct PTTLSIdentity: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPTypes.swift` | 306 | `public enum PTHTTPTLSConfiguration: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsTransfer/PTTransferDownloadController.swift` | 13 | `final class PTTransferDownloadController: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsUIFoundation/PTRichTextCache.swift` | 7 | `final class PTTextMatcherCache: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PhotoPicker/PTFetchImageOperation.swift` | 20 | `final class PTFetchImageOperation: Operation, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 18 | `private struct PTSafeMediaBox<T>: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 26 | `public struct PTSendableDictionaryBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/SocketKit/PTWebSocketClient.swift` | 363 | `private final class PTURLSessionWebSocketDelegateProxy: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/VideoEditor/CompositionInstruction.swift` | 11 | `class CompositionInstruction: AVMutableVideoCompositionInstruction, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/Compositor.swift` | 15 | `public final class Compositor: NSObject, AVVideoCompositing, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/Exporter.swift` | 19 | `struct PTSystemAVAssetBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/PTVideoEditorToolsTrimControl.swift` | 13 | `private struct PTSafeMediaBox<T>: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift` | 1535 | `private struct PTC7SafeBox:@unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/VideoConverter.swift` | 47 | `private struct PTSafeAudioExportBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/Vision/PTVision.swift` | 27 | `private struct PTObservationBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |

## 版本门槛

- 新业务模型不得新增 `@unchecked Sendable`。
- 新的系统对象包装器必须在 `Scripts/unchecked_sendable_allowlist.txt` 登记，并说明保护方式与替代版本。
- `nonisolated(unsafe)` 不得用于业务共享状态。
