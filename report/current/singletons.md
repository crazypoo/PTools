<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_singletons.rb
Source revision: 0726ca37b7560eed16d61e69b2835daafa3e2f17
Generated at: 2026-10-06T03:52:24Z
-->

# PTools 当前单例范围盘点

本报告用于后续 DI 迁移；它不会自动改变现有单例生命周期。

- .shared / .share 调用文本计数：**1642**
- 单例声明计数：**131**

| 位置 | 名称 | 分类 | 声明 | 迁移建议 |
| --- | --- | --- | --- | --- |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:15 | shared | D Shared mutable UI or scene state | public static let shared = PTAlertConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:147 | shared | D Shared mutable UI or scene state | public static let shared = PTAlertManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:89 | share | D Shared mutable UI or scene state | public static let share = PTLaunchAdMonitor() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Banner/PTBannerPresenter.swift:413 | shared | C Shared mutable service | public static let shared = PTBannerCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Base/PTAppBaseConfig.swift:18 | share | D Shared mutable UI or scene state | public static let share = PTAppBaseConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Base/PTAudioCache.swift:132 | shared | B Thread-safe shared cache or resource | public static let shared = PTAudioCacheFileManager() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTAudioCache.swift:234 | shared | B Thread-safe shared cache or resource | public static let shared = PTAudioService() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTNavigationBarManager.swift:136 | shared | D Shared mutable UI or scene state | public static let shared = PTNavigationBarManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Base/PTVideoCoverCache.swift:54 | shared | B Thread-safe shared cache or resource | public static let shared = PTVideoManager() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTVideoCoverCache.swift:115 | shared | B Thread-safe shared cache or resource | static let shared = PTVideoFileDownloadCoordinator() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTVideoCoverCache.swift:182 | shared | B Thread-safe shared cache or resource | public static let shared = PTVideoFileCache() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/BioID/PTBiologyID.swift:23 | shared | C Shared mutable service | public static let shared = PTBiometricsManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/BluetoothPermission/PTPermissionBluetoothHandler.swift:25 | shared | C Shared mutable service | @MainActor static let shared: PTPermissionBluetoothHandler = .init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/C7Collector/C7CameraConfig.swift:14 | share | D Shared mutable UI or scene state | public static let share = C7CameraConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:37 | share | D Shared mutable UI or scene state | public static let share = PTCameraFilterConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:21 | share | C Shared mutable service | public static let share = PTHarBethFilter(name: "", type: .cigaussian) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:19 | share | C Shared mutable service | public static let share = PTCallMessageMailFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:17 | shared | C Shared mutable service | public static let shared = PTPhoneBlock() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:49 | shared | C Shared mutable service | public static let shared = PTRefreshConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:15 | share | C Shared mutable service | @MainActor public static let share = PTCheckFWords() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:338 | share | C Shared mutable service | @MainActor public static let share = PTCheckUpdateFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Contact/PTContact.swift:48 | share | C Shared mutable service | public static let share = PTContact() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTAppUserdefault.swift:45 | shared | C Shared mutable service | public static let shared = PTCoreUserDefultsWrapper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTGCDManager.swift:49 | shared | C Shared mutable service | public static let shared = PTGCDManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTMediaCache.swift:62 | shared | B Thread-safe shared cache or resource | public static let shared = PTMediaCache() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:250 | shared | A Stateless convenience or immutable utility | public static let shared = PTMemoryWarningCoordinator() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Core/PTUtils.swift:298 | share | A Stateless convenience or immutable utility | public static let share = PTUtils() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Country/PTCountryCodes.swift:19 | share | C Shared mutable service | @MainActor public static let share = PTCountryCodes() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DEBUGLocation/PTDebugLocationKit.swift:14 | shared | C Shared mutable service | static let shared = PTDebugLocationKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DarkMode/PTDrakModeOption.swift:107 | shared | D Shared mutable UI or scene state | static let shared = PTDarkModeScheduleMonitor() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DarkMode/PTThemeProvider.swift:397 | shared | D Shared mutable UI or scene state | public static let shared = LegacyThemeProvider() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:190 | shared | C Shared mutable service | public static let shared = PTDebugPreferences() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:457 | shared | C Shared mutable service | public static let shared = PTDebugEventCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:484 | shared | C Shared mutable service | public static let shared = PTDebugManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:600 | shared | C Shared mutable service | static let shared = PTDebugPluginManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:626 | shared | C Shared mutable service | public static let shared = PTDebugWindowCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugHookRegistry.swift:27 | shared | C Shared mutable service | public static let shared = PTDebugHookRegistry() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDevFunction.swift:15 | share | C Shared mutable service | public static let share = PTDevFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTInstruments.swift:781 | shared | C Shared mutable service | static let shared = PTTraceRuntime() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTInstruments.swift:1127 | shared | C Shared mutable service | public static let shared = PTInstrumentRecorder() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/StdoutCapture.swift:14 | shared | C Shared mutable service | private static let shared = StdoutCapture() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:25 | share | D Shared mutable UI or scene state | public static let share = PTColorPickPlugin() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:274 | share | D Shared mutable UI or scene state | static let share = PTColorPickWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:201 | shared | C Shared mutable service | @MainActor public static let shared = PTCrashHandler() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugFile/PTFileBrowser.swift:15 | shared | A Stateless convenience or immutable utility | public static let shared = PTFileBrowser() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:241 | shared | C Shared mutable service | public static let shared = PTNetworkSpeedMonitor() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTHttpDatasource.swift:13 | shared | C Shared mutable service | static let shared = PTHttpDatasource() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift:8 | shared | C Shared mutable service | public static let shared = PTNetworkCaptureStore() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTNetworkCaptureStore.swift:173 | shared | C Shared mutable service | public static let shared = PTNetworkCaptureCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTNetworkDebugSupport.swift:82 | shared | C Shared mutable service | public static let shared = PTDebugHookRegistryStore() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTNetworkHelper.swift:17 | shared | C Shared mutable service | static let shared = PTNetworkHelper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugPerformance/PTDebugPerformanceToolKit.swift:14 | shared | C Shared mutable service | static let shared = PTDebugPerformanceToolKit.init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:14 | shared | C Shared mutable service | public static let shared = PTFPSTool.init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:17 | share | D Shared mutable UI or scene state | public static let share = PTViewRulerPlugin.init() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/HealthKit/PTHealthKit.swift:16 | share | C Shared mutable service | public static let share = PTHealthKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/IAP/PTIAPManager.swift:24 | shared | C Shared mutable service | public static let shared = PTIAPManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:36 | share | D Shared mutable UI or scene state | public static let share = PTImageEditorConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Inspector/ViewHierarchy.swift:11 | shared | C Shared mutable service | static let shared = ViewHierarchy(application: .shared) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Instructions/PTInstructionCoordinator.swift:600 | shared | C Shared mutable service | public static let shared = PTInstructionSessionRegistry() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Instructions/PTInstructionCoordinator.swift:639 | shared | C Shared mutable service | public static let shared = PTInstructionCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Instructions/PTInstructionPersistence.swift:25 | shared | C Shared mutable service | public static let shared = PTUserDefaultsInstructionStore() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Instructions/PTInstructionTargetRegistry.swift:12 | shared | C Shared mutable service | public static let shared = PTInstructionTargetRegistry() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Language/PTLanguage.swift:300 | share | C Shared mutable service | public static let share = PTLanguage() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:18 | shared | D Shared mutable UI or scene state | public static let shared = PTLaunchProfiler() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:193 | shared | D Shared mutable UI or scene state | public static let shared = LaunchVisualizer() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:260 | share | D Shared mutable UI or scene state | static let share = EntryWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:86 | shared | C Shared mutable service | public static let shared = PTLivePhoto() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Loading/PTHudView.swift:41 | share | D Shared mutable UI or scene state | public static let share = PTHudConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/LocalConsole.swift:155 | shared | D Shared mutable UI or scene state | static let shared = PTConsoleWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/LocalConsole.swift:404 | shared | D Shared mutable UI or scene state | public static let shared = LocalConsole() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/ResizeController.swift:17 | shared | D Shared mutable UI or scene state | public static let shared = ResizeController() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/SystemReport.swift:12 | shared | D Shared mutable UI or scene state | @MainActor public static let shared = SystemReport() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Location/PTGetGPSData.swift:18 | share | C Shared mutable service | public static let share = PTGetGPSData() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LocationPermission/PTPermissionLocationAlwaysHandler.swift:75 | shared | C Shared mutable service | static var shared: PTPermissionLocationAlwaysHandler? | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LocationPermission/PTPermissionLocationWhenInUseHandler.swift:83 | shared | C Shared mutable service | @MainActor static var shared: PTPermissionLocationWhenInUseHandler? | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Log/PTLogFileManager.swift:15 | shared | C Shared mutable service | public static let shared = PTLogFileManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:15 | shared | C Shared mutable service | public static let shared = MetricsManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:36 | share | C Shared mutable service | public static let share = PTMediaBrowserConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MessageKit/PTChatConfig.swift:42 | share | C Shared mutable service | public static let share = PTChatConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Motion/PTMotion.swift:83 | shared | C Shared mutable service | public static let shared = PTMotion() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NFC/PTNFCToolKit.swift:51 | shared | C Shared mutable service | public static let shared = PTNFCToolKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:23 | shared | C Shared mutable service | public static let shared = NetworkReachability() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:62 | shared | C Shared mutable service | public static let shared = PTNetWorkStatus() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:259 | shared | B Thread-safe shared cache or resource | static let shared = NetworkCache() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/NetWork/NetworkTypes.swift:295 | shared | C Shared mutable service | public static let shared = RequestDeduplicator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/PTNetworkArchitecture.swift:181 | shared | C Shared mutable service | public static let shared = PTNetworkExecutor(network: .share) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:71 | shared | C Shared mutable service | public static let shared = PTNetworkSpeedTester() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:218 | shared | C Shared mutable service | public static let shared = PTNetworkSpeedTestFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/OSSKit/OSSSpeech.swift:201 | shared | C Shared mutable service | public static let shared = OSSSpeech() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Overlay/PTOverlayCore.swift:205 | shared | C Shared mutable service | public static let shared = PTOverlayDiagnostics() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Overlay/PTOverlayCore.swift:246 | shared | C Shared mutable service | public static let shared = PTOverlayRegistryStore() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Overlay/PTOverlayGeometry.swift:37 | shared | C Shared mutable service | public static let shared = PTAnchorRegistry() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsAccessibility/PTAccessibility.swift:97 | shared | C Shared mutable service | public static let shared = PTAccessibilityFocusCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsAppIntents/PTAppIntents.swift:38 | shared | C Shared mutable service | public static let shared = PTAppIntentRouteBridge() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsAudio/PTAudio.swift:83 | shared | C Shared mutable service | public static let shared = PTAudioSessionCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsAudio/PTAudio.swift:199 | shared | C Shared mutable service | public static let shared = PTAudioSessionCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsBackgroundTasks/PTBackgroundTasks.swift:89 | shared | C Shared mutable service | public static let shared = PTBackgroundTasks() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsBluetooth/PTBluetooth.swift:361 | shared | C Shared mutable service | public static let shared = PTBluetoothCentral() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsConnectivity/PTConnectivity.swift:102 | shared | C Shared mutable service | public static let shared = PTConnectivityMonitor() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsCore/PTFeedbackCenter.swift:26 | shared | C Shared mutable service | public static let shared = PTFeedbackCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsDocuments/PTDocuments.swift:134 | shared | C Shared mutable service | public static let shared = PTDocumentPickerCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsFeedback/PTFeedback.swift:76 | shared | C Shared mutable service | public static let shared = PTHapticEngine() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsNotifications/PTNotifications.swift:231 | shared | C Shared mutable service | public static let shared = PTNotificationCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsSimulation/PTSimulation.swift:23 | shared | C Shared mutable service | public static let shared = PTSimulationRuntime(environment: .init()) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsTheme/PTTheme.swift:283 | shared | C Shared mutable service | public static let shared = PTThemeRegistry() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PToolsWidgetCore/PTWidgetCore.swift:94 | shared | C Shared mutable service | public static let shared = PTWidgetReloadCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:18 | share | C Shared mutable service | public static let share = PTPermissionStatic() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:206 | share | D Shared mutable UI or scene state | public static let share = PTMediaLibConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:372 | share | D Shared mutable UI or scene state | public static let share = PTMediaLibUIConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Picker/PTBasePickerView.swift:132 | shared | D Shared mutable UI or scene state | public static var shared = PTPickerStyle() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Ping/PTPingActivityIndicator.swift:13 | shared | C Shared mutable service | static let shared = PTPingActivityIndicator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Popover/PTPopover.swift:205 | shared | C Shared mutable service | public static let shared = PTPopoverCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Protocol/PTProtocol.swift:96 | shared | A Stateless convenience or immutable utility | public static let shared = PTAdapterConfig() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Protocol/PTProtocol.swift:122 | share | A Stateless convenience or immutable utility | public static let share = PTNumberValueAdapter() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Rotation/PTRotationManager.swift:34 | shared | D Shared mutable UI or scene state | public static let shared = PTRotationManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Router/PTRouteHostCoordinator.swift:13 | shared | C Shared mutable service | public static let shared = PTRouteHostCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouteRouter.swift:28 | shared | C Shared mutable service | public static let shared = PooToolsRouter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouterDynamicParamsMapping.swift:23 | shared | C Shared mutable service | static let shared: PTRouterDynamicParamsMapping = { | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouterServiceManager.swift:32 | shared | C Shared mutable service | public static let shared = PTRouterServiceManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouterServiceManager.swift:178 | shared | C Shared mutable service | public static let shared = PTServiceActionMapper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:16 | shared | C Shared mutable service | static let shared = PTBannerVideoManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:52 | shared | C Shared mutable service | public static let shared = PTBannerPlayerManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:19 | shared | D Shared mutable UI or scene state | public static let shared = PTBannerScheduler() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/SocketKit/PTSocketManager.swift:36 | share | C Shared mutable service | public static let share = PTSocketManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Speech/PTSpeech.swift:25 | share | C Shared mutable service | public static let share = PTSpeech() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/StatusBar/StatusBarManager.swift:35 | shared | D Shared mutable UI or scene state | public static let shared = StatusBarManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:17 | share | C Shared mutable service | public static let share = PTVideoEditorConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Vision/PTVision.swift:36 | share | C Shared mutable service | public static var share: PTVision { | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:15 | share | C Shared mutable service | public static let share = PTFaceEye() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:16 | shared | C Shared mutable service | public static let shared = PTiCloudFileManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/iOS17Tips/PTTip.swift:110 | shared | C Shared mutable service | public static let shared = PTTip() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
