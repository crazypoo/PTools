<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_cocoapods_subspec_graph.rb
Source revision: e9ae991e3411ea728be377c2e82b1635af069c05
Generated at: 2026-10-03T14:20:49Z
-->

# CocoaPods Subspec Graph

- Schema: `1`
- Podspec: `PooTools` `5.60.0`
- Default subspec: `Core`
- iOS: `17.0`
- Swift: `6.0`
- Subspec count: `142`

## Subspecs

| Subspec | Local dependencies | Third-party dependencies | Source directories | Frameworks | Resources |
| --- | --- | --- | --- | --- | --- |
| `Accessibility` | `PooTools/PToolsUIFoundation` | — | `PToolsAccessibility` | Foundation, UIKit | — |
| `Activities` | — | — | `PToolsActivities` | ActivityKit, Foundation | — |
| `AppIntents` | `PooTools/RouteCore` | — | `PToolsAppIntents` | AppIntents, Foundation | — |
| `Appz` | `PooTools/Core` | `Appz` | — | — | — |
| `Audio` | `PooTools/MicPermission` | — | `PToolsAudio` | AVFoundation, AudioToolbox, Foundation | — |
| `BackgroundTasks` | — | — | `PToolsBackgroundTasks` | BackgroundTasks, Foundation | — |
| `BankCard` | `PooTools/Core` | — | `BankCard` | — | — |
| `Banner` | `PooTools/Logging`, `PooTools/Overlay`, `PooTools/PToolsCore`, `PooTools/Symbols` | — | `Banner` | Foundation, UIKit | — |
| `BilogyID` | `PooTools/BioID` | — | — | — | — |
| `BioID` | `PooTools/Core`, `PooTools/FaceIDPermission`, `PooTools/KeyChain` | — | `BioID` | LocalAuthentication, Security | — |
| `Bluetooth` | — | — | `PToolsBluetooth` | CoreBluetooth, Foundation | — |
| `BluetoothPermission` | `PooTools/Core` | — | `BluetoothPermission` | — | — |
| `Calendar` | `PooTools/CalendarPermission`, `PooTools/Core`, `PooTools/RemindersPermission` | — | `Calendar` | EventKit | — |
| `CalendarPermission` | `PooTools/PToolsPermissionCore` | — | `CalendarPermission` | — | — |
| `CameraPermission` | `PooTools/PToolsPermissionCore` | — | `CameraPermission` | — | — |
| `CheckBox` | — | — | `CheckBox` | — | — |
| `CheckDirtyWord` | — | — | `CheckDirtyWord` | — | PooToolsCheckDirtyWordResource |
| `CheckUpdate` | `PooTools/NetWork` | `SwiftJWT` | `CheckUpdate` | — | — |
| `ChinesePinyin` | `PooTools/Core` | — | `Pinyin` | — | — |
| `Circle` | `PooTools/Core` | — | `Circle` | — | — |
| `CodeView` | `PooTools/Core` | — | `CodeView` | — | — |
| `Configuration` | `PooTools/Storage` | — | `PToolsConfiguration` | Foundation | — |
| `Connectivity` | — | — | `PToolsConnectivity` | Foundation, Network | — |
| `Contact` | `PooTools/ContactsPermission`, `PooTools/Core` | — | `Contact` | — | — |
| `ContactsPermission` | `PooTools/PToolsPermissionCore` | — | `ContactsPermission` | — | — |
| `ContentState` | `PooTools/Accessibility`, `PooTools/Connectivity`, `PooTools/Core`, `PooTools/Theme` | — | `PToolsContentState` | Foundation, UIKit | — |
| `Core` | `PooTools/Date`, `PooTools/Device`, `PooTools/Logging`, `PooTools/PToolsCore`, `PooTools/PToolsUIFoundation`, `PooTools/Symbols` | `IQKeyboardManagerSwift`, `IQKeyboardToolbarManager`, `Kingfisher`, `SnapKit`, `lottie-ios` | `ActionsheetAndAlert`, `Animation`, `AppDelegate`, `AppStore`, `ApplicationFunction`, `Badge`, `Base`, `BlackMagic`, `Blur`, `Button`, `Category`, `Colors`, `Core`, `DarkMode`, `FloatPanel`, `Font`, `Foundation`, `Language`, `Line`, `Log`, `PToolsFontCore`, `PermissionCore`, `PhotoLibraryPermission`, `Protocol`, `Rotation`, `SideMenuControl`, `StatusBar`, `Switch`, `iCloud` | AVFoundation, AVKit, AudioToolbox, CoreFoundation, CoreText, Foundation, Photos, UIKit | PooToolsResource |
| `Country` | `PooTools/Core` | — | `Country` | — | — |
| `CustomerLabel` | `PooTools/Core` | — | `Label` | QuartzCore | — |
| `CustomerNumberKeyboard` | `PooTools/Core` | — | `Keyboard` | — | — |
| `DEBUG` | `PooTools/BackgroundTasks`, `PooTools/Connectivity`, `PooTools/Core`, `PooTools/DeepLink`, `PooTools/NetWork`, `PooTools/Notifications`, `PooTools/Overlay`, `PooTools/PDF`, `PooTools/RouteCore`, `PooTools/SearchBar`, `PooTools/Share`, `PooTools/Storage`, `PooTools/Symbols` | — | `DEBUGLocation`, `Debug`, `DebugCategory`, `DebugColor`, `DebugCrash`, `DebugFile`, `DebugLibs`, `DebugNetwork`, `DebugPerformance`, `DebugRuler`, `DebugUserDefault`, `DevMask`, `Inspector`, `LocalConsole`, `TouchInspector` | — | — |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` | — | `WhereIsMyEye` | — | — |
| `DataEncrypt` | `PooTools/Core` | `CryptoSwift` | `AESAndDES` | — | — |
| `Date` | — | — | `PToolsDate` | Foundation | — |
| `DeepLink` | `PooTools/RouteCore` | — | `PToolsDeepLink` | Foundation | — |
| `Device` | — | — | `PToolsDevice` | Foundation | — |
| `Documents` | `PooTools/PDF` | — | `PToolsDocuments` | Foundation, QuickLook, UIKit, UniformTypeIdentifiers | — |
| `FaceIDPermission` | `PooTools/PToolsPermissionCore` | — | `FaceIDPermission` | — | — |
| `Feedback` | `PooTools/PToolsCore` | — | `PToolsFeedback` | CoreHaptics, Foundation, UIKit | — |
| `FilterCamera` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/MediaViewer`, `PooTools/MicPermission` | — | `FilterCamera` | — | — |
| `Flag` | `PooTools/Core` | `FlagKit` | — | — | — |
| `Form` | `PooTools/Accessibility`, `PooTools/CheckBox`, `PooTools/ContentState`, `PooTools/Core`, `PooTools/Input`, `PooTools/PToolsCore`, `PooTools/Picker`, `PooTools/Slider`, `PooTools/Stepper`, `PooTools/Theme` | — | `PToolsForm` | Foundation, UIKit | — |
| `GCDWebServer` | `PooTools/HTTPFilePortal` | — | — | — | — |
| `Guide` | `PooTools/Core`, `PooTools/PageControl` | — | `Guide` | — | — |
| `HTTPFilePortal` | `PooTools/HTTPServer` | — | `PToolsHTTPFilePortal` | Foundation | PooToolsSource/PToolsHTTPFilePortal/Resources/**/* |
| `HTTPServer` | — | — | `PToolsHTTPServer` | Foundation, Network, Security, UniformTypeIdentifiers | — |
| `HandSign` | `PooTools/Core` | — | `SignView` | — | — |
| `HarbethKit` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/Symbols` | `Harbeth` | `C7Collector` | — | — |
| `HealthPermission` | `PooTools/PToolsPermissionCore` | — | `HealthPermission` | — | — |
| `HeartRate` | `PooTools/CameraPermission`, `PooTools/Core` | `lottie-ios` | `HeartRate` | — | — |
| `Hud` | `PooTools/Core`, `PooTools/ProgressBar` | — | `Hud` | — | — |
| `IAP` | `PooTools/Core` | — | `IAP` | — | — |
| `ImageEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/MediaCore`, `PooTools/PhotoPicker`, `PooTools/Symbols` | — | `ImageEditor` | — | — |
| `ImagePicker` | `PooTools/CameraPermission`, `PooTools/Core` | — | `ImagePicker` | — | — |
| `Input` | `PooTools/Core` | `PhoneNumberKit` | `Input` | — | — |
| `InputAll` | `PooTools/Appz`, `PooTools/Audio`, `PooTools/BankCard`, `PooTools/Banner`, `PooTools/BilogyID`, `PooTools/Calendar`, `PooTools/CheckBox`, `PooTools/CheckDirtyWord`, `PooTools/CheckUpdate`, `PooTools/ChinesePinyin`, `PooTools/Circle`, `PooTools/CodeView`, `PooTools/Configuration`, `PooTools/Core`, `PooTools/Country`, `PooTools/CustomerLabel`, `PooTools/CustomerNumberKeyboard`, `PooTools/DEBUG`, `PooTools/DEBUG_TrackingEyes`, `PooTools/DataEncrypt`, `PooTools/Feedback`, `PooTools/Flag`, `PooTools/Guide`, `PooTools/HTTPFilePortal`, `PooTools/HarbethKit`, `PooTools/HeartRate`, `PooTools/Hud`, `PooTools/IAP`, `PooTools/ImageEditor`, `PooTools/Input`, `PooTools/Instructions`, `PooTools/KeyChain`, `PooTools/LaunchTimeProfiler`, `PooTools/Layout`, `PooTools/LivePhoto`, `PooTools/Loading`, `PooTools/Location`, `PooTools/MediaViewer`, `PooTools/MessageKit`, `PooTools/Motion`, `PooTools/NetWork`, `PooTools/OSSKitSpeech`, `PooTools/PDF`, `PooTools/PageControl`, `PooTools/PagingControl`, `PooTools/PhoneInfo`, `PooTools/PhotoPicker`, `PooTools/Picker`, `PooTools/Ping`, `PooTools/PopoverKit`, `PooTools/ProgressBar`, `PooTools/RateView`, `PooTools/Router`, `PooTools/SVG`, `PooTools/ScanQRCode`, `PooTools/ScrollBanner`, `PooTools/Search`, `PooTools/SearchBar`, `PooTools/Security`, `PooTools/SecuritySuite`, `PooTools/Segmented`, `PooTools/Share`, `PooTools/Slider`, `PooTools/SmartScreenshot`, `PooTools/SocketKit`, `PooTools/Stepper`, `PooTools/Tabbar`, `PooTools/Telephony`, `PooTools/VideoEditor`, `PooTools/Vision`, `PooTools/WhatsNewsKit`, `PooTools/ZipArchive`, `PooTools/iOS17Tips` | — | — | — | — |
| `Instructions` | `PooTools/Core`, `PooTools/Overlay` | — | `Instructions` | — | — |
| `KeyChain` | — | — | `KeyChain` | — | — |
| `LaunchTimeProfiler` | `PooTools/Core` | — | `LaunchTimeProfiler` | — | — |
| `Layout` | `PooTools/Core` | `CollectionViewPagingLayout` | `Layout` | — | — |
| `LivePhoto` | `PooTools/Core` | — | `LivePhoto` | — | — |
| `Loading` | `PooTools/Core` | — | `Loading` | — | — |
| `Location` | `PooTools/Core`, `PooTools/LocationPermission` | — | `Location` | CoreLocation | — |
| `LocationPermission` | `PooTools/PToolsPermissionCore` | — | `LocationPermission` | — | — |
| `Logging` | — | — | `PToolsLogging` | Foundation, OSLog | — |
| `MXMetricManagerKit` | `PooTools/Core` | — | `MXMetricKitManager` | — | — |
| `MediaCore` | — | — | `PToolsMediaCore` | Foundation | — |
| `MediaPermission` | `PooTools/PToolsPermissionCore` | — | `MeidaLibraryPermission` | — | — |
| `MediaViewer` | `PooTools/Core`, `PooTools/LivePhoto`, `PooTools/MediaCore`, `PooTools/PageControl`, `PooTools/ProgressBar` | — | `MediaViewer` | Photos | — |
| `MeidaPermission` | `PooTools/MediaPermission` | — | — | — | — |
| `MessageKit` | `PooTools/Core`, `PooTools/CustomerLabel`, `PooTools/Symbols` | — | `MessageKit` | — | — |
| `MicPermission` | `PooTools/PToolsPermissionCore` | — | `MicPermission` | — | — |
| `Model` | `PooTools/ModelCore` | — | `PToolsModel` | Foundation | — |
| `ModelCore` | — | — | `PToolsModelCore` | Foundation | — |
| `ModelLegacyKakaJSON` | `PooTools/Core` | `KakaJSON` | `PToolsModelLegacyKakaJSON` | Foundation | — |
| `ModelLegacySmartCodable` | — | `SmartCodable` | `PToolsModelLegacySmartCodable` | Foundation | — |
| `Motion` | `PooTools/Core`, `PooTools/MotionPermission` | — | `Motion` | CoreMotion | — |
| `MotionPermission` | `PooTools/PToolsPermissionCore` | — | `MotionPermission` | — | — |
| `NFCKit` | `PooTools/Core` | — | `NFC` | — | — |
| `NetWork` | `PooTools/Network` | — | — | — | — |
| `Network` | `PooTools/Core`, `PooTools/Loading`, `PooTools/ModelCore`, `PooTools/ModelLegacyKakaJSON`, `PooTools/ModelLegacySmartCodable` | `Alamofire` | `NetWork`, `NetWorkModelCore` | — | — |
| `NetworkSpeedTest` | `PooTools/Core` | — | `NetworkSpeedTest` | — | — |
| `NotificationBanner` | `PooTools/Banner` | — | — | — | — |
| `NotificationPermission` | `PooTools/PToolsPermissionCore` | — | `NotificationPermission` | — | — |
| `Notifications` | `PooTools/NotificationPermission`, `PooTools/RouteCore` | — | `PToolsNotifications` | Foundation, UniformTypeIdentifiers, UserNotifications | — |
| `OSSKitSpeech` | `PooTools/Core`, `PooTools/SpeechRecognizerPermission` | — | `OSSKit` | Speech | — |
| `Overlay` | `PooTools/Logging`, `PooTools/PToolsCore`, `PooTools/PToolsUIFoundation` | — | `Overlay` | Foundation, UIKit | — |
| `PDF` | `PooTools/Core` | — | `PDF` | — | — |
| `PToolsCore` | — | — | `PToolsCore` | Foundation | — |
| `PToolsModelCombine` | — | — | `PToolsModelCombine` | Combine, Foundation | — |
| `PToolsModelUIKit` | `PooTools/ModelCore` | — | `PToolsModelUIKit` | Foundation, UIKit | — |
| `PToolsPermissionCore` | — | — | `PToolsPermissionCore` | Foundation | — |
| `PToolsPermissionUI` | `PooTools/PToolsPermissionCore`, `PooTools/PToolsUIFoundation` | — | `PToolsPermissionUI` | Foundation, UIKit | — |
| `PToolsUIFoundation` | `PooTools/PToolsCore` | `SnapKit` | `PToolsUIFoundation` | Foundation, UIKit | — |
| `PageControl` | `PooTools/Core` | — | `PageControl` | — | — |
| `PagingControl` | `PooTools/Core` | — | `SegmentControl` | — | — |
| `PhoneInfo` | — | — | `PhoneInfo` | Security | — |
| `PhotoPicker` | `PooTools/Core`, `PooTools/ImagePicker`, `PooTools/Loading`, `PooTools/MediaCore`, `PooTools/Symbols` | `Kakapos` | `PhotoPicker` | — | — |
| `Picker` | `PooTools/Core` | — | `Picker` | — | — |
| `Ping` | `PooTools/Core` | — | `Ping` | — | — |
| `Popover` | `PooTools/Overlay`, `PooTools/Symbols` | — | `Popover` | — | — |
| `PopoverKit` | `PooTools/PToolsCore`, `PooTools/Popover` | — | — | — | — |
| `ProgressBar` | `PooTools/Core` | — | `ProgressBar` | — | — |
| `RateView` | `PooTools/PToolsUIFoundation` | `SnapKit` | `RateView` | — | — |
| `RemindersPermission` | `PooTools/PToolsPermissionCore` | — | `RemindersPermission` | — | — |
| `RouteCore` | — | — | `PToolsRouteCore` | Foundation | — |
| `Router` | `PooTools/Core`, `PooTools/DeepLink`, `PooTools/RouteCore` | — | `Router` | — | — |
| `SVG` | `PooTools/Core` | `PocketSVG`, `Protobuf`, `SVGAPlayer` | `KingfisherSVG` | — | — |
| `ScanQRCode` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/PhotoPicker` | — | `QRCodeScan` | — | — |
| `ScrollBanner` | `PooTools/Core`, `PooTools/PageControl` | — | `ScrollBanner` | — | — |
| `Search` | `PooTools/Core`, `PooTools/PToolsUIFoundation`, `PooTools/SearchBar` | — | `Search` | — | — |
| `SearchBar` | `PooTools/Core` | — | `SearchBar` | — | — |
| `Security` | — | — | `Security` | CryptoKit, Foundation, LocalAuthentication, Security | — |
| `SecuritySuite` | `PooTools/Core` | `IOSSecuritySuite` | — | — | — |
| `Segmented` | `PooTools/Core` | — | `Segmented` | — | — |
| `Share` | `PooTools/CustomerLabel` | — | `Share` | — | — |
| `Simulation` | `PooTools/Bluetooth`, `PooTools/Connectivity`, `PooTools/PToolsCore`, `PooTools/PToolsDevice`, `PooTools/SimulationCore` | — | `PToolsSimulation` | Foundation | — |
| `SimulationCore` | — | — | `PToolsSimulationCore` | Foundation | — |
| `SiriPermission` | `PooTools/Core` | — | `SiriPermission` | — | — |
| `Slider` | `PooTools/PToolsUIFoundation` | `SnapKit` | `Slider` | — | — |
| `SmartScreenshot` | `PooTools/Core` | — | `ScreenShot` | — | — |
| `SocketKit` | `PooTools/Core`, `PooTools/Logging` | — | `SocketKit` | — | — |
| `SpeechRecognizerPermission` | `PooTools/PToolsPermissionCore` | — | `SpeechPremission` | — | — |
| `SpeedPanel` | `PooTools/Core` | — | `SpeedPanel` | — | — |
| `StepCount` | `PooTools/Core`, `PooTools/HealthPermission` | — | `HealthKit` | HealthKit | — |
| `Stepper` | `PooTools/Core` | — | `Stepper` | — | — |
| `Storage` | `PooTools/KeyChain`, `PooTools/StorageCore` | — | `PToolsStorage` | Foundation, Security | — |
| `StorageCore` | — | — | `PToolsStorageCore` | Foundation | — |
| `Symbols` | — | — | `PToolsSymbols` | Foundation, OSLog, UIKit | PooToolsSymbolsResources |
| `Tabbar` | `PooTools/Core` | — | — | — | — |
| `Telephony` | `PooTools/Core` | — | `CallMessageMail` | CoreTelephony, MessageUI, WebKit | — |
| `Theme` | `PooTools/PToolsUIFoundation` | — | `PToolsTheme` | Foundation, UIKit | — |
| `TipsView` | `PooTools/Core` | — | `TipsView` | — | — |
| `TrackingPermission` | `PooTools/PToolsPermissionCore` | — | `TrackingPermission` | — | — |
| `VideoCache` | `PooTools/Core` | `KTVHTTPCache` | — | — | — |
| `VideoEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/Loading`, `PooTools/MediaCore`, `PooTools/ProgressBar`, `PooTools/Symbols` | — | `VideoEditor` | — | — |
| `Vision` | `PooTools/Core` | — | `Vision` | — | — |
| `WebKit` | `PooTools/Core` | — | `WebKit` | — | — |
| `WhatsNewsKit` | `PooTools/Core` | — | `WhatsNewsKit` | — | — |
| `WidgetCore` | `PooTools/DeepLink`, `PooTools/RouteCore`, `PooTools/Storage` | — | `PToolsWidgetCore` | Foundation, WidgetKit | — |
| `ZipArchive` | `PooTools/Core` | `SSZipArchive` | — | — | — |
| `iOS17Tips` | `PooTools/Core` | — | `iOS17Tips` | — | — |

## Notes

- This report parses the checked-in podspec and does not resolve or change external Pods.
- `PooTools/Core` is represented by its complete source-directory list because it is the default subspec boundary.
- Legacy spelling differences remain visible so the parity gate can classify them instead of silently hiding them.
