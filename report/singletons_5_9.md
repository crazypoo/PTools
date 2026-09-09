# PTools 5.9.x 单例范围盘点

本报告用于后续 DI 迁移；它不会自动改变现有单例生命周期。

- .shared 调用文本计数：**658**
- 单例声明计数：**60**

| 位置 | 分类 | 声明 |
| --- | --- | --- |
| PooToolsSource/ActionsheetAndAlert/PTAlertConfig.swift:15 | UI or lifecycle state | public static let shared = PTAlertConfig() |
| PooToolsSource/ActionsheetAndAlert/PTAlertManager.swift:148 | UI or lifecycle state | public static let shared = PTAlertManager() |
| PooToolsSource/Base/PTAudioCache.swift:96 | UI or lifecycle state | public static let shared = PTAudioCacheFileManager() |
| PooToolsSource/Base/PTAudioCache.swift:164 | UI or lifecycle state | public static let shared = PTAudioService() |
| PooToolsSource/Base/PTBaseViewController.swift:138 | UI or lifecycle state | public static let shared = PTNavigationBarManager() |
| PooToolsSource/Base/PTVideoCoverCache.swift:63 | UI or lifecycle state | public static let shared = PTVideoManager() |
| PooToolsSource/Base/PTVideoCoverCache.swift:123 | UI or lifecycle state | public static let shared = PTVideoFileCache() |
| PooToolsSource/BioID/PTBiologyID.swift:23 | legacy/global state | public static let shared = PTBiometricsManager() |
| PooToolsSource/BluetoothPermission/PTPermissionBluetoothHandler.swift:18 | service or shared resource | @MainActor static let shared: PTPermissionBluetoothHandler = .init() |
| PooToolsSource/CallMessageMail/PTPhoneBlock.swift:18 | legacy/global state | public static let shared = PTPhoneBlock() |
| PooToolsSource/Category/UIScrollView+PTRefreshEX.swift:50 | legacy/global state | public static let shared = PTRefreshConfig() |
| PooToolsSource/Core/PTAppUserdefault.swift:50 | legacy/global state | public static let shared = PTCoreUserDefultsWrapper() |
| PooToolsSource/Core/PTGCDManager.swift:33 | legacy/global state | public static let shared = PTGCDManager() |
| PooToolsSource/DEBUGLocation/PTDebugLocationKit.swift:14 | legacy/global state | static let shared = PTDebugLocationKit() |
| PooToolsSource/DarkMode/PTDrakModeOption.swift:107 | legacy/global state | static let shared = PTDarkModeScheduleMonitor() |
| PooToolsSource/DarkMode/PTThemeProvider.swift:205 | legacy/global state | static let shared = LegacyThemeProvider() |
| PooToolsSource/Debug/PTApplicationDirectories.swift:12 | legacy/global state | static let shared = PTApplicationDirectories() |
| PooToolsSource/Debug/StdoutCapture.swift:18 | legacy/global state | private static let shared = StdoutCapture() |
| PooToolsSource/DebugCrash/PTCrashHandler.swift:206 | legacy/global state | @MainActor public static let shared = PTCrashHandler() |
| PooToolsSource/DebugFile/PTFileBrowser.swift:15 | legacy/global state | public static let shared = PTFileBrowser() |
| PooToolsSource/DebugNetwork/PTCustomHTTPProtocol.swift:400 | service or shared resource | public static let shared = PTNetworkSpeedMonitor() |
| PooToolsSource/DebugNetwork/PTHttpDatasource.swift:13 | service or shared resource | static let shared = PTHttpDatasource() |
| PooToolsSource/DebugNetwork/PTNetworkHelper.swift:17 | service or shared resource | static let shared = PTNetworkHelper() |
| PooToolsSource/DebugPerformance/PTDebugPerformanceToolKit.swift:14 | legacy/global state | static let shared = PTDebugPerformanceToolKit.init() |
| PooToolsSource/DebugPerformance/PTFPSTool.swift:14 | legacy/global state | public static let shared = PTFPSTool.init() |
| PooToolsSource/IAP/PTIAPManager.swift:20 | legacy/global state | public static let shared = PTIAPManager() |
| PooToolsSource/Inspector/ViewHierarchy.swift:11 | UI or lifecycle state | static let shared = ViewHierarchy(application: .shared) |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:19 | legacy/global state | public static let shared = PTLaunchProfiler() |
| PooToolsSource/LaunchTimeProfiler/PTLaunchProfiler.swift:191 | legacy/global state | public static let shared = LaunchVisualizer() |
| PooToolsSource/LivePhoto/PTLivePhoto.swift:86 | legacy/global state | public static let shared = PTLivePhoto() |
| PooToolsSource/LocalConsole/LocalConsole.swift:139 | UI or lifecycle state | static let shared = PTConsoleWindow() |
| PooToolsSource/LocalConsole/LocalConsole.swift:283 | UI or lifecycle state | static let shared = PTDebugPluginManager() |
| PooToolsSource/LocalConsole/LocalConsole.swift:324 | UI or lifecycle state | public static let shared = LocalConsole() |
| PooToolsSource/LocalConsole/ResizeController.swift:18 | UI or lifecycle state | public static let shared = ResizeController() |
| PooToolsSource/LocalConsole/SystemReport.swift:12 | UI or lifecycle state | @MainActor public static let shared = SystemReport() |
| PooToolsSource/LocationPermission/PTPermissionLocationAlwaysHandler.swift:56 | service or shared resource | static var shared: PTPermissionLocationAlwaysHandler? |
| PooToolsSource/LocationPermission/PTPermissionLocationWhenInUseHandler.swift:66 | service or shared resource | @MainActor static var shared: PTPermissionLocationWhenInUseHandler? |
| PooToolsSource/Log/PTLogFileManager.swift:5 | legacy/global state | public static let shared = PTLogFileManager() |
| PooToolsSource/MXMetricKitManager/MetricsManager.swift:15 | legacy/global state | public static let shared = MetricsManager() |
| PooToolsSource/Motion/PTMotion.swift:83 | legacy/global state | public static let shared = PTMotion() |
| PooToolsSource/NFC/PTNFCToolKit.swift:51 | legacy/global state | public static let shared = PTNFCToolKit() |
| PooToolsSource/NetWork/Network.swift:93 | service or shared resource | public static let shared = NetworkReachability() |
| PooToolsSource/NetWork/Network.swift:140 | service or shared resource | public static let shared = PTNetWorkStatus() |
| PooToolsSource/NetWork/Network.swift:317 | service or shared resource | static let shared = NetworkCache() |
| PooToolsSource/NetWork/Network.swift:544 | service or shared resource | public static let shared = RequestDeduplicator() |
| PooToolsSource/NetworkSpeedTest/PTNetworkSpeedTestFunction.swift:27 | service or shared resource | public static let shared = PTNetworkSpeedTestFunction() |
| PooToolsSource/OSSKit/OSSSpeech.swift:198 | legacy/global state | public static let shared = OSSSpeech() |
| PooToolsSource/Picker/PTBasePickerView.swift:125 | UI or lifecycle state | public static var shared = PTPickerStyle() |
| PooToolsSource/Ping/PTPingActivityIndicator.swift:13 | legacy/global state | static let shared = PTPingActivityIndicator() |
| PooToolsSource/Protocol/PTProtocol.swift:96 | legacy/global state | public static let shared = PTAdapterConfig() |
| PooToolsSource/Rotation/PTRotationManager.swift:32 | legacy/global state | public static let shared = PTRotationManager() |
| PooToolsSource/Router/PTRouterDynamicParamsMapping.swift:23 | legacy/global state | static let shared: PTRouterDynamicParamsMapping = { |
| PooToolsSource/Router/PTRouterServiceManager.swift:30 | legacy/global state | public static let shared = PTRouterServiceManager() |
| PooToolsSource/Router/PTRouterServiceManager.swift:176 | legacy/global state | public static let shared = PTServiceActionMapper() |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:16 | legacy/global state | static let shared = PTBannerVideoManager() |
| PooToolsSource/ScrollBanner/PTBannerMediaManager.swift:52 | legacy/global state | public static let shared = PTBannerPlayerManager() |
| PooToolsSource/ScrollBanner/PTBannerView.swift:18 | legacy/global state | public static let shared = PTBannerScheduler() |
| PooToolsSource/StatusBar/StatusBarManager.swift:35 | legacy/global state | public static let shared = StatusBarManager() |
| PooToolsSource/iCloud/PTiCloudFileManager.swift:16 | legacy/global state | public static let shared = PTiCloudFileManager() |
| PooToolsSource/iOS17Tips/PTTip.swift:96 | legacy/global state | public static let shared = PTTip() |
