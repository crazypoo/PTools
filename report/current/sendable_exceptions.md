<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: fd66ba388d2f4b8448b52d434ef02d2fdfd5d56e
Source version: 5.59.0
Source inputs digest: f65daecb5c4328289fea7efd63b8becda2567f98942e0f2f1c6937ded0182aa9
Generator version: 1
Generator: Scripts/report_sendable_exceptions.rb
Generated at: 2026-10-01T14:20:09Z
-->

# Swift 6 Sendable 例外清单

本文件由 `Scripts/report_sendable_exceptions.rb` 生成；它只记录现状，不把 `@unchecked Sendable` 视为无条件安全。

| 类型/声明位置 | 行号 | 声明 | 白名单 | 处理原则 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/C7Collector/C7CollectorCamera.swift` | 18 | `private struct PTSystemPixelBufferBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 15 | `private struct PTSendableEventStoreBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 19 | `public struct PTSendableEventArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 27 | `public struct PTSendableReminderArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/AVExport+PTEX.swift` | 13 | `public struct PTAssetExportResult: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 21 | `public struct PTSendableAVAsset: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 45 | `private struct PTSendableExportSession: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PTVideoThumbnailService.swift` | 37 | `private struct PTVideoAssetSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 87 | `public final class PTTFPaging: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 93 | `public final class PTTFMeta: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 98 | `public final class PTTLinkMainModel: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 103 | `public final class PTTFRelationships: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 120 | `public final class PTTFLinks: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 134 | `public final class PTTFIconAssetTokenModle: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 142 | `public final class PTTFAttributes: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 173 | `public final class PTTFVersionData: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 183 | `public final class PTTFModelCollection: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 191 | `public final class PTTFNewerBuildVersionModel: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 205 | `public final class PTTFUpdateCustomModel: Codable, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 214 | `public class PTCheckUpdateFunction: NSObject,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Core/OSSVoice.swift` | 162 | `public class OSSVoice: AVSpeechSynthesisVoice, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Debug/PTApplicationDirectories.swift` | 11 | `final class PTApplicationDirectories: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Debug/StdoutCapture.swift` | 11 | `struct PTReadCompletionNotificationBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 14 | `private struct PTSafeExceptionBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 18 | `private struct PTSafeSignalPointerBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugLibs/PTLoadedLibsFunction.swift` | 30 | `final class PTLoadedLibrariesViewModel: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift` | 26 | `final class PTCustomHTTPProtocol: URLProtocol, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/ImageEditor/PTWeakProxy.swift` | 11 | `public final class PTWeakProxy: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Inspector/KeyboardAnimatable.swift` | 11 | `private final class PTWeakSelfBox<T: AnyObject>: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Inspector/KeyboardAnimatable.swift` | 17 | `private final class PTNotificationBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Inspector/KeyboardAnimatable.swift` | 23 | `private final class PTKeyboardActionBox<Anim, Comp>: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Inspector/MainThreadAsyncOperation.swift` | 9 | `final class MainThreadAsyncOperation: MainThreadOperation, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Inspector/MainThreadOperation.swift` | 9 | `class MainThreadOperation: Operation, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 17 | `private final class AVContext: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 37 | `private struct PTAVSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/LivePhoto/PTLivePhoto.swift` | 44 | `private final class ProgressState: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/MXMetricKitManager/MetricsManager.swift` | 13 | `public final class MetricsManager: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Motion/PTMotion.swift` | 81 | `public class PTMotion: NSObject, @unchecked Sendable,CMHeadphoneMotionManagerDelegate {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 14 | `private struct PTNFCSessionAndTagSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 19 | `private struct PTNFCSessionSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NFC/PTNFCToolKit.swift` | 23 | `private struct PTNFCSessionAndNDEFSendableBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 150 | `public final class Network: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 924 | `private struct PTLegacyModelTypeBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 18 | `public final class NetworkReachability: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/NetworkSupport.swift` | 66 | `public final class PTNetWorkStatus: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 126 | `public class OSSSpeech: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 382 | `final class ConverterState: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSUtterance.swift` | 27 | `public class OSSUtterance: AVSpeechUtterance, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsActivities/PTActivities.swift` | 88 | `private final class PTActivityKitSendableBox<Value>: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPServer.swift` | 68 | `private final class PTHTTPNetworkConnectionTransport: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPTypes.swift` | 300 | `public struct PTTLSIdentity: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsHTTPServer/PTHTTPTypes.swift` | 306 | `public enum PTHTTPTLSConfiguration: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PToolsUIFoundation/PTRichText.swift` | 409 | `private final class PTTextMatcherCache: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PhotoPicker/PTFetchImageOperation.swift` | 20 | `final class PTFetchImageOperation: Operation, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 18 | `private struct PTSafeMediaBox<T>: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 26 | `public struct PTSendableDictionaryBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/Router/PTRouterManager.swift` | 23 | `private struct PTServiceTypeBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Router/PTRouterServiceManager.swift` | 13 | `public final class PTLegacyRouterServiceBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SocketKit/PTWebSocketClient.swift` | 363 | `private final class PTURLSessionWebSocketDelegateProxy: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/TouchInspector/TouchInspectorWindow.swift` | 15 | `private struct PTTouchValueBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
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
