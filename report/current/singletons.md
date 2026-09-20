<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_singletons_5_9.rb
Source revision: 70977e9fff1f55366be262a39e2529fd993e6456
Generated at: 2026-09-20T01:45:21Z
-->

# PTools 当前单例范围盘点

本报告用于后续 DI 迁移；它不会自动改变现有单例生命周期。

- .shared / .share 调用文本计数：**1515**
- 单例声明计数：**100**

| 位置 | 名称 | 分类 | 声明 | 迁移建议 |
| --- | --- | --- | --- | --- |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:15 | shared | D Shared mutable UI or scene state | public static let shared = PTAlertConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:148 | shared | D Shared mutable UI or scene state | public static let shared = PTAlertManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/ApplicationFunction/PTLaunchAdMonitor.swift:91 | share | D Shared mutable UI or scene state | public static let share = PTLaunchAdMonitor() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Base/PTAppBaseConfig.swift:16 | share | D Shared mutable UI or scene state | public static let share = PTAppBaseConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Base/PTAudioCache.swift:96 | shared | B Thread-safe shared cache or resource | public static let shared = PTAudioCacheFileManager() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTAudioCache.swift:164 | shared | B Thread-safe shared cache or resource | public static let shared = PTAudioService() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTNavigationBarManager.swift:137 | shared | D Shared mutable UI or scene state | public static let shared = PTNavigationBarManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Base/PTVideoCoverCache.swift:113 | shared | B Thread-safe shared cache or resource | public static let shared = PTVideoManager() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/Base/PTVideoCoverCache.swift:173 | shared | B Thread-safe shared cache or resource | public static let shared = PTVideoFileCache() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/BioID/PTBiologyID.swift:23 | shared | C Shared mutable service | public static let shared = PTBiometricsManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/BluetoothPermission/PTPermissionBluetoothHandler.swift:22 | shared | C Shared mutable service | @MainActor static let shared: PTPermissionBluetoothHandler = .init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/C7Collector/C7CameraConfig.swift:14 | share | D Shared mutable UI or scene state | public static let share = C7CameraConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/C7Collector/PTCameraFilterConfig.swift:35 | share | D Shared mutable UI or scene state | public static let share = PTCameraFilterConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/C7Collector/PTHarBethFilter.swift:21 | share | C Shared mutable service | public static let share = PTHarBethFilter(name: "", type: .cigaussian) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CallMessageMail/PTCallMessageMailFunction.swift:19 | share | C Shared mutable service | public static let share = PTCallMessageMailFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:18 | shared | C Shared mutable service | public static let shared = PTPhoneBlock() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:50 | shared | C Shared mutable service | public static let shared = PTRefreshConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CheckDirtyWord/PTCheckFWords.swift:15 | share | C Shared mutable service | @MainActor public static let share = PTCheckFWords() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/CheckUpdate/PTCheckUpdateFunction.swift:215 | share | C Shared mutable service | @MainActor public static let share = PTCheckUpdateFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Contact/PTContact.swift:48 | share | C Shared mutable service | public static let share = PTContact() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTAppUserdefault.swift:45 | shared | C Shared mutable service | public static let shared = PTCoreUserDefultsWrapper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTGCDManager.swift:49 | shared | C Shared mutable service | public static let shared = PTGCDManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Core/PTUtils+SceneConcurrency.swift:250 | shared | A Stateless convenience or immutable utility | public static let shared = PTMemoryWarningCoordinator() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Core/PTUtils.swift:298 | share | A Stateless convenience or immutable utility | public static let share = PTUtils() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Country/PTCountryCodes.swift:19 | share | C Shared mutable service | @MainActor public static let share = PTCountryCodes() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DEBUGLocation/PTDebugLocationKit.swift:14 | shared | C Shared mutable service | static let shared = PTDebugLocationKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DarkMode/PTDrakModeOption.swift:107 | shared | D Shared mutable UI or scene state | static let shared = PTDarkModeScheduleMonitor() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DarkMode/PTThemeProvider.swift:370 | shared | D Shared mutable UI or scene state | public static let shared = LegacyThemeProvider() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Debug/PTApplicationDirectories.swift:12 | shared | A Stateless convenience or immutable utility | static let shared = PTApplicationDirectories() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Debug/PTDebugFunction.swift:190 | shared | C Shared mutable service | public static let shared = PTDebugPreferences() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:457 | shared | C Shared mutable service | public static let shared = PTDebugEventCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:484 | shared | C Shared mutable service | public static let shared = PTDebugManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:580 | shared | C Shared mutable service | static let shared = PTDebugPluginManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDebugFunction.swift:606 | shared | C Shared mutable service | public static let shared = PTDebugWindowCoordinator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTDevFunction.swift:15 | share | C Shared mutable service | public static let share = PTDevFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTInstruments.swift:666 | shared | C Shared mutable service | static let shared = PTTraceRuntime() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/PTInstruments.swift:982 | shared | C Shared mutable service | public static let shared = PTInstrumentRecorder() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Debug/StdoutCapture.swift:18 | shared | C Shared mutable service | private static let shared = StdoutCapture() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:26 | share | D Shared mutable UI or scene state | public static let share = PTColorPickPlugin() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DebugColor/PTColorPickPlugin.swift:275 | share | D Shared mutable UI or scene state | static let share = PTColorPickWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:206 | shared | C Shared mutable service | @MainActor public static let shared = PTCrashHandler() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugFile/PTFileBrowser.swift:15 | shared | A Stateless convenience or immutable utility | public static let shared = PTFileBrowser() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:419 | shared | C Shared mutable service | public static let shared = PTNetworkSpeedMonitor() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTHttpDatasource.swift:13 | shared | C Shared mutable service | static let shared = PTHttpDatasource() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugNetwork/PTNetworkHelper.swift:17 | shared | C Shared mutable service | static let shared = PTNetworkHelper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugPerformance/PTDebugPerformanceToolKit.swift:14 | shared | C Shared mutable service | static let shared = PTDebugPerformanceToolKit.init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:14 | shared | C Shared mutable service | public static let shared = PTFPSTool.init() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/DebugRuler/PTViewRulerPlugin.swift:16 | share | D Shared mutable UI or scene state | public static let share = PTViewRulerPlugin.init() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/HealthKit/PTHealthKit.swift:17 | share | C Shared mutable service | public static let share = PTHealthKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/IAP/PTIAPManager.swift:20 | shared | C Shared mutable service | public static let shared = PTIAPManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ImageEditor/PTImageEditorConfig.swift:36 | share | D Shared mutable UI or scene state | public static let share = PTImageEditorConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Inspector/ViewHierarchy.swift:11 | shared | C Shared mutable service | static let shared = ViewHierarchy(application: .shared) | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Language/PTLanguage.swift:300 | share | C Shared mutable service | public static let share = PTLanguage() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:19 | shared | D Shared mutable UI or scene state | public static let shared = PTLaunchProfiler() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:191 | shared | D Shared mutable UI or scene state | public static let shared = LaunchVisualizer() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:255 | share | D Shared mutable UI or scene state | static let share = EntryWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:86 | shared | C Shared mutable service | public static let shared = PTLivePhoto() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Loading/PTHudView.swift:38 | share | D Shared mutable UI or scene state | public static let share = PTHudConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/LocalConsole.swift:144 | shared | D Shared mutable UI or scene state | static let shared = PTConsoleWindow() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/LocalConsole.swift:362 | shared | D Shared mutable UI or scene state | public static let shared = LocalConsole() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/ResizeController.swift:18 | shared | D Shared mutable UI or scene state | public static let shared = ResizeController() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/LocalConsole/SystemReport.swift:12 | shared | D Shared mutable UI or scene state | @MainActor public static let shared = SystemReport() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Location/PTGetGPSData.swift:15 | share | C Shared mutable service | public static let share = PTGetGPSData() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LocationPermission/PTPermissionLocationAlwaysHandler.swift:71 | shared | C Shared mutable service | static var shared: PTPermissionLocationAlwaysHandler? | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/LocationPermission/PTPermissionLocationWhenInUseHandler.swift:79 | shared | C Shared mutable service | @MainActor static var shared: PTPermissionLocationWhenInUseHandler? | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Log/PTLogFileManager.swift:5 | shared | C Shared mutable service | public static let shared = PTLogFileManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Log/PTNSLog.swift:86 | shared | C Shared mutable service | public static let shared = PTLogSinkCenter() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:15 | shared | C Shared mutable service | public static let shared = MetricsManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MediaViewer/PTMediaBrowserConfig.swift:36 | share | C Shared mutable service | public static let share = PTMediaBrowserConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/MessageKit/PTChatConfig.swift:42 | share | C Shared mutable service | public static let share = PTChatConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Motion/PTMotion.swift:83 | shared | C Shared mutable service | public static let shared = PTMotion() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NFC/PTNFCToolKit.swift:51 | shared | C Shared mutable service | public static let shared = PTNFCToolKit() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:15 | shared | C Shared mutable service | public static let shared = NetworkReachability() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:62 | shared | C Shared mutable service | public static let shared = PTNetWorkStatus() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetWork/NetworkSupport.swift:239 | shared | B Thread-safe shared cache or resource | static let shared = NetworkCache() | 保留共享入口，但必须有容量、过期和清理策略 |
| PooToolsSource/NetWork/NetworkTypes.swift:234 | shared | C Shared mutable service | public static let shared = RequestDeduplicator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:27 | shared | C Shared mutable service | public static let shared = PTNetworkSpeedTestFunction() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/OSSKit/OSSSpeech.swift:198 | shared | C Shared mutable service | public static let shared = OSSSpeech() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PermissionCore/PTPermissionViewController.swift:19 | share | C Shared mutable service | public static let share = PTPermissionStatic() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:204 | share | D Shared mutable UI or scene state | public static let share = PTMediaLibConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/PhotoPicker/PTMediaLibConfig.swift:363 | share | D Shared mutable UI or scene state | public static let share = PTMediaLibUIConfig() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Picker/PTBasePickerView.swift:130 | shared | D Shared mutable UI or scene state | public static var shared = PTPickerStyle() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Ping/PTPingActivityIndicator.swift:13 | shared | C Shared mutable service | static let shared = PTPingActivityIndicator() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Protocol/PTProtocol.swift:96 | shared | A Stateless convenience or immutable utility | public static let shared = PTAdapterConfig() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Protocol/PTProtocol.swift:122 | share | A Stateless convenience or immutable utility | public static let share = PTNumberValueAdapter() | 优先保留；有可变状态时迁移为实例配置 |
| PooToolsSource/Rotation/PTRotationManager.swift:34 | shared | D Shared mutable UI or scene state | public static let shared = PTRotationManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/Router/PTRouterDynamicParamsMapping.swift:23 | shared | C Shared mutable service | static let shared: PTRouterDynamicParamsMapping = { | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouterServiceManager.swift:30 | shared | C Shared mutable service | public static let shared = PTRouterServiceManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Router/PTRouterServiceManager.swift:176 | shared | C Shared mutable service | public static let shared = PTServiceActionMapper() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:16 | shared | C Shared mutable service | static let shared = PTBannerVideoManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:52 | shared | C Shared mutable service | public static let shared = PTBannerPlayerManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/ScrollBanner/PTBannerView.swift:18 | shared | D Shared mutable UI or scene state | public static let shared = PTBannerScheduler() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/SocketKit/PTSocketManager.swift:45 | share | C Shared mutable service | public static let share = PTSocketManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Speech/PTSpeech.swift:25 | share | C Shared mutable service | public static let share = PTSpeech() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/StatusBar/StatusBarManager.swift:35 | shared | D Shared mutable UI or scene state | public static let shared = StatusBarManager() | 按 Scene 或控制器实例保存；保留兼容入口 |
| PooToolsSource/VideoEditor/PTVideoEditorConfig.swift:15 | share | C Shared mutable service | public static let share = PTVideoEditorConfig() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/Vision/PTVision.swift:31 | share | C Shared mutable service | public static let share = PTVision() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/WhereIsMyEye/PTFaceEye.swift:15 | share | C Shared mutable service | public static let share = PTFaceEye() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:16 | shared | C Shared mutable service | public static let shared = PTiCloudFileManager() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
| PooToolsSource/iOS17Tips/PTTip.swift:96 | shared | C Shared mutable service | public static let shared = PTTip() | 提供可实例化入口，shared/share 仅作为默认兼容入口 |
