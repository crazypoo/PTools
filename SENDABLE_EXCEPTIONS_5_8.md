# Swift 6 Sendable 例外清单

本文件由 `Scripts/report_sendable_exceptions.rb` 生成；它只记录现状，不把 `@unchecked Sendable` 视为无条件安全。

| 类型/声明位置 | 行号 | 声明 | 白名单 | 处理原则 |
| --- | ---: | --- | --- | --- |
| `PooToolsSource/C7Collector/C7CollectorCamera.swift` | 18 | `private struct PTSystemPixelBufferBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 13 | `private struct PTSendableEventStoreBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 17 | `public struct PTSendableEventArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Calendar/PTEventOnCalendar.swift` | 25 | `public struct PTSendableReminderArrayBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/AVExport+PTEX.swift` | 13 | `public struct PTAssetExportResult: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 26 | `private struct PTSendableExportSession: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Category/PHAsset+PTEX.swift` | 56 | `struct PTSendableAVAsset: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 89 | `public class PTTFPaging :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 95 | `public class PTTFMeta :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 100 | `public class PTTLinkMainModel:PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 105 | `public class PTTFRelationships :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 122 | `public class PTTFLinks :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 134 | `public class PTTFIconAssetTokenModle:PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 142 | `public class PTTFAttributes :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 173 | `public class PTTFVersionData :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 183 | `public class PTTFModelCollection :PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 191 | `public class PTTFNewerBuildVersionModel:PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 205 | `public class PTTFUpdateCustomModel:PTCodableModelProtocol,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift` | 214 | `public class PTCheckUpdateFunction: NSObject,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Core/OSSVoice.swift` | 162 | `public class OSSVoice: AVSpeechSynthesisVoice, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Debug/PTApplicationDirectories.swift` | 11 | `final class PTApplicationDirectories: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/Debug/StdoutCapture.swift` | 11 | `struct PTReadCompletionNotificationBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 14 | `private struct PTSafeExceptionBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugCrash/PTCrashHandler.swift` | 18 | `private struct PTSafeSignalPointerBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugLibs/PTLoadedLibsFunction.swift` | 30 | `final class PTLoadedLibrariesViewModel: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift` | 22 | `final class PTCustomHTTPProtocol: URLProtocol, @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift` | 25 | `struct UncheckedSendableBox<T>: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift` | 75 | `// 状态属性（由于声明了 @unchecked Sendable，我们需要确保对其修改都在 threadOperator 内）` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/ImageEditor/PTWeakProxy.swift` | 11 | `public final class PTWeakProxy: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/ImagePicker/PTImagePicker.swift` | 589 | `private struct SendableBox<T>: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
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
| `PooToolsSource/NetWork/Network.swift` | 89 | `/// 🌟 步骤 1：标记为 @unchecked Sendable。` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 91 | `public final class NetworkReachability: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 139 | `public final class PTNetWorkStatus: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 672 | `public final class Network: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 1230 | `private struct PTSafeUploadParamsBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/NetWork/Network.swift` | 1502 | `private struct PTLegacyModelTypeBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 125 | `/// 使用 @unchecked Sendable 搭配内部状态锁机制，完全适配 Swift 6 并发模型。` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 126 | `public class OSSSpeech: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 380 | `// 【Swift 6 规范】定义一个内部引用类型容器来持有状态，并标记为 @unchecked Sendable` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSSpeech.swift` | 382 | `final class ConverterState: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/OSSKit/OSSUtterance.swift` | 27 | `public class OSSUtterance: AVSpeechUtterance, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/PhotoPicker/PTFetchImageOperation.swift` | 20 | `final class PTFetchImageOperation: Operation, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 18 | `private struct PTSafeMediaBox<T>: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/PhotoPicker/PTMediaLibManager.swift` | 26 | `public struct PTSendableDictionaryBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/Router/PTRouterManager.swift` | 23 | `private struct PTServiceTypeBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Router/PTRouterServiceManager.swift` | 13 | `public final class PTLegacyRouterServiceBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift` | 12 | `// 🚀 核心终极修复：增加 @unchecked Sendable 协议。` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SegmentControl/PTMainSegmentDataSource.swift` | 16 | `public class PTMainSegmentDataSource: JXSegmentedBaseDataSource, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SegmentControl/PTMainSegmentModel.swift` | 23 | `public class PTMainSegmentModel: JXSegmentedTitleItemModel,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SegmentControl/PTSegmentControlBaseModel.swift` | 11 | `public final class PTSegmentControlBaseModel: NSObject,@unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SocketKit/PTSocketManager.swift` | 40 | `// 4. 声明 @unchecked Sendable。我们通过内部的 socketQueue 串行队列手动保证了线程安全` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/SocketKit/PTSocketManager.swift` | 42 | `public final class PTSocketManager: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/TouchInspector/TouchInspectorWindow.swift` | 15 | `private struct PTTouchValueBox: @unchecked Sendable {` | yes | 诊断/运行时兼容边界，待诊断目标隔离 |
| `PooToolsSource/VideoEditor/CompositionInstruction.swift` | 11 | `class CompositionInstruction: AVMutableVideoCompositionInstruction, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/Compositor.swift` | 12 | `// ⭐️ 核心改进 1：声明为 @unchecked Sendable。` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/Compositor.swift` | 15 | `public final class Compositor: NSObject, AVVideoCompositing, @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/Exporter.swift` | 19 | `struct PTSystemAVAssetBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/PTVideoEditorToolsTrimControl.swift` | 14 | `private struct PTSafeMediaBox<T>: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift` | 1519 | `private struct PTC7SafeBox:@unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/VideoEditor/VideoConverter.swift` | 30 | `private struct PTSafeAudioExportBox: @unchecked Sendable {` | yes | 系统媒体对象窄边界，继续用快照或生命周期保护 |
| `PooToolsSource/Vision/PTVision.swift` | 24 | `private struct PTObservationBox: @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |
| `PooToolsSource/Vision/PTVision.swift` | 29 | `public final class PTVision: NSObject, @unchecked Sendable {` | yes | 兼容边界；不得新增业务共享状态 |

## 版本门槛

- 新业务模型不得新增 `@unchecked Sendable`。
- 新的系统对象包装器必须在 `Scripts/unchecked_sendable_allowlist.txt` 登记，并说明保护方式与替代版本。
- `nonisolated(unsafe)` 不得用于业务共享状态。
