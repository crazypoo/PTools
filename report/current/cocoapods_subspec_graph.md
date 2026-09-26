<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/report_cocoapods_subspec_graph.rb
Source revision: 864d17a08c0444c34f1393e33bb9d37f2faf7e86
Generated at: 2026-09-26T14:52:58Z
-->

# CocoaPods Subspec Graph

- Schema: `1`
- Podspec: `PooTools` `5.26.0`
- Default subspec: `Core`
- iOS: `17.0`
- Swift: `6.0`
- Subspec count: `109`

## Subspecs

| Subspec | Local dependencies | Third-party dependencies | Source directories | Frameworks | Resources |
| --- | --- | --- | --- | --- | --- |
| `Appz` | `PooTools/Core` | `Appz` | — | — | — |
| `BankCard` | `PooTools/Core` | — | `BankCard` | — | — |
| `BilogyID` | `PooTools/BioID` | — | — | — | — |
| `BioID` | `PooTools/Core`, `PooTools/FaceIDPermission`, `PooTools/KeyChain` | — | `BioID` | LocalAuthentication, Security | — |
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
| `Contact` | `PooTools/ContactsPermission`, `PooTools/Core` | — | `Contact` | — | — |
| `ContactsPermission` | `PooTools/PToolsPermissionCore` | — | `ContactsPermission` | — | — |
| `Core` | `PooTools/Date`, `PooTools/Logging`, `PooTools/PToolsCore`, `PooTools/PToolsUIFoundation`, `PooTools/Symbols` | `DeviceKit`, `IQKeyboardManagerSwift`, `IQKeyboardToolbarManager`, `KakaJSON`, `Kingfisher`, `SmartCodable`, `SmartCodable/Inherit`, `SnapKit`, `lottie-ios` | `ActionsheetAndAlert`, `Animation`, `AppDelegate`, `AppStore`, `ApplicationFunction`, `Badge`, `Base`, `BlackMagic`, `Blur`, `Button`, `Category`, `Colors`, `Core`, `DarkMode`, `FloatPanel`, `Font`, `Foundation`, `Language`, `Line`, `Log`, `PermissionCore`, `PhotoLibraryPermission`, `Protocol`, `Rotation`, `SideMenuControl`, `StatusBar`, `Switch`, `iCloud` | AVFoundation, AVKit, AudioToolbox, CoreFoundation, CoreText, Foundation, Photos, UIKit | PooToolsResource |
| `Country` | `PooTools/Core` | — | `Country` | — | — |
| `CustomerLabel` | `PooTools/Core` | — | `Label` | QuartzCore | — |
| `CustomerNumberKeyboard` | `PooTools/Core` | — | `Keyboard` | — | — |
| `DEBUG` | `PooTools/Core`, `PooTools/NetWork`, `PooTools/PDF`, `PooTools/SearchBar`, `PooTools/Share`, `PooTools/Symbols` | — | `DEBUGLocation`, `Debug`, `DebugCategory`, `DebugColor`, `DebugCrash`, `DebugFile`, `DebugLibs`, `DebugNetwork`, `DebugPerformance`, `DebugRuler`, `DebugUserDefault`, `DevMask`, `Inspector`, `LocalConsole`, `TouchInspector` | — | — |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` | — | `WhereIsMyEye` | — | — |
| `DataEncrypt` | `PooTools/Core` | `CryptoSwift` | `AESAndDES` | — | — |
| `Date` | — | — | `PToolsDate` | Foundation | — |
| `FaceIDPermission` | `PooTools/PToolsPermissionCore` | — | `FaceIDPermission` | — | — |
| `FilterCamera` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/MediaViewer`, `PooTools/MicPermission` | — | `FilterCamera` | — | — |
| `Flag` | `PooTools/Core` | `FlagKit` | — | — | — |
| `GCDWebServer` | `PooTools/Core` | `GCDWebServer`, `GCDWebServer/WebUploader` | — | — | — |
| `Guide` | `PooTools/Core`, `PooTools/PageControl` | — | `Guide` | — | — |
| `HandSign` | `PooTools/Core` | — | `SignView` | — | — |
| `HarbethKit` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/Symbols` | `Harbeth` | `C7Collector` | — | — |
| `HealthPermission` | `PooTools/PToolsPermissionCore` | — | `HealthPermission` | — | — |
| `HeartRate` | `PooTools/CameraPermission`, `PooTools/Core` | `lottie-ios` | `HeartRate` | — | — |
| `Hud` | `PooTools/Core`, `PooTools/ProgressBar` | — | `Hud` | — | — |
| `IAP` | `PooTools/Core` | — | `IAP` | — | — |
| `ImageEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/MediaCore`, `PooTools/PhotoPicker`, `PooTools/Symbols` | — | `ImageEditor` | — | — |
| `ImagePicker` | `PooTools/CameraPermission`, `PooTools/Core` | — | `ImagePicker` | — | — |
| `Input` | `PooTools/Core` | `PhoneNumberKit` | `Input` | — | — |
| `InputAll` | `PooTools/Appz`, `PooTools/BankCard`, `PooTools/BilogyID`, `PooTools/Calendar`, `PooTools/CheckBox`, `PooTools/CheckDirtyWord`, `PooTools/CheckUpdate`, `PooTools/ChinesePinyin`, `PooTools/Circle`, `PooTools/CodeView`, `PooTools/Core`, `PooTools/Country`, `PooTools/CustomerLabel`, `PooTools/CustomerNumberKeyboard`, `PooTools/DEBUG`, `PooTools/DEBUG_TrackingEyes`, `PooTools/DataEncrypt`, `PooTools/Flag`, `PooTools/GCDWebServer`, `PooTools/Guide`, `PooTools/HarbethKit`, `PooTools/HeartRate`, `PooTools/Hud`, `PooTools/IAP`, `PooTools/ImageEditor`, `PooTools/Input`, `PooTools/Instructions`, `PooTools/KeyChain`, `PooTools/LaunchTimeProfiler`, `PooTools/Layout`, `PooTools/LivePhoto`, `PooTools/Loading`, `PooTools/Location`, `PooTools/MediaViewer`, `PooTools/MessageKit`, `PooTools/Motion`, `PooTools/NetWork`, `PooTools/NotificationBanner`, `PooTools/OSSKitSpeech`, `PooTools/PDF`, `PooTools/PageControl`, `PooTools/PagingControl`, `PooTools/PhoneInfo`, `PooTools/PhotoPicker`, `PooTools/Picker`, `PooTools/Ping`, `PooTools/PopoverKit`, `PooTools/ProgressBar`, `PooTools/RateView`, `PooTools/Router`, `PooTools/SVG`, `PooTools/ScanQRCode`, `PooTools/ScrollBanner`, `PooTools/Search`, `PooTools/SearchBar`, `PooTools/Security`, `PooTools/SecuritySuite`, `PooTools/Segmented`, `PooTools/Share`, `PooTools/Slider`, `PooTools/SmartScreenshot`, `PooTools/SocketKit`, `PooTools/Stepper`, `PooTools/Tabbar`, `PooTools/Telephony`, `PooTools/VideoEditor`, `PooTools/Vision`, `PooTools/WhatsNewsKit`, `PooTools/ZipArchive`, `PooTools/iOS17Tips` | — | — | — | — |
| `Instructions` | `PooTools/Core` | `Instructions` | — | — | — |
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
| `Motion` | `PooTools/Core`, `PooTools/MotionPermission` | — | `Motion` | CoreMotion | — |
| `MotionPermission` | `PooTools/PToolsPermissionCore` | — | `MotionPermission` | — | — |
| `NFCKit` | `PooTools/Core` | — | `NFC` | — | — |
| `NetWork` | `PooTools/Network` | — | — | — | — |
| `Network` | `PooTools/Core`, `PooTools/Loading` | `Alamofire` | `NetWork` | — | — |
| `NetworkSpeedTest` | `PooTools/Core` | — | `NetworkSpeedTest` | — | — |
| `NotificationBanner` | `PooTools/Core` | `NotificationBannerSwift` | — | — | — |
| `NotificationPermission` | `PooTools/PToolsPermissionCore` | — | `NotificationPermission` | — | — |
| `OSSKitSpeech` | `PooTools/Core`, `PooTools/SpeechRecognizerPermission` | — | `OSSKit` | Speech | — |
| `PDF` | `PooTools/Core` | — | `PDF` | — | — |
| `PToolsCore` | — | — | `PToolsCore` | Foundation | — |
| `PToolsPermissionCore` | — | — | `PToolsPermissionCore` | Foundation | — |
| `PToolsPermissionUI` | `PooTools/PToolsPermissionCore`, `PooTools/PToolsUIFoundation` | — | `PToolsPermissionUI` | Foundation, UIKit | — |
| `PToolsUIFoundation` | `PooTools/PToolsCore` | `SnapKit` | `PToolsUIFoundation` | Foundation, UIKit | — |
| `PageControl` | `PooTools/Core` | — | `PageControl` | — | — |
| `PagingControl` | `PooTools/Core` | `JXPagingView/Paging`, `JXSegmentedView` | `SegmentControl` | — | — |
| `PhoneInfo` | — | — | `PhoneInfo` | Security | — |
| `PhotoPicker` | `PooTools/Core`, `PooTools/ImagePicker`, `PooTools/Loading`, `PooTools/MediaCore`, `PooTools/Symbols` | `Kakapos` | `PhotoPicker` | — | — |
| `Picker` | `PooTools/Core` | — | `Picker` | — | — |
| `Ping` | `PooTools/Core` | — | `Ping` | — | — |
| `PopoverKit` | `PooTools/Core` | `Popovers` | — | — | — |
| `ProgressBar` | `PooTools/Core` | — | `ProgressBar` | — | — |
| `RateView` | `PooTools/PToolsUIFoundation` | `SnapKit` | `RateView` | — | — |
| `RemindersPermission` | `PooTools/PToolsPermissionCore` | — | `RemindersPermission` | — | — |
| `Router` | `PooTools/Core` | — | `Router` | — | — |
| `SVG` | `PooTools/Core` | `PocketSVG`, `Protobuf`, `SVGAPlayer` | `KingfisherSVG` | — | — |
| `ScanQRCode` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/PhotoPicker` | — | `QRCodeScan` | — | — |
| `ScrollBanner` | `PooTools/Core`, `PooTools/PageControl` | — | `ScrollBanner` | — | — |
| `Search` | `PooTools/Core`, `PooTools/PToolsUIFoundation`, `PooTools/SearchBar` | — | `Search` | — | — |
| `SearchBar` | `PooTools/Core` | — | `SearchBar` | — | — |
| `Security` | — | — | `Security` | CryptoKit, Foundation, LocalAuthentication, Security | — |
| `SecuritySuite` | `PooTools/Core` | `IOSSecuritySuite` | — | — | — |
| `Segmented` | `PooTools/Core` | — | `Segmented` | — | — |
| `Share` | `PooTools/CustomerLabel` | — | `Share` | — | — |
| `SiriPermission` | `PooTools/Core` | — | `SiriPermission` | — | — |
| `Slider` | `PooTools/PToolsUIFoundation` | `SnapKit` | `Slider` | — | — |
| `SmartScreenshot` | `PooTools/Core` | — | `ScreenShot` | — | — |
| `SocketKit` | `PooTools/Core` | `SocketRocket` | `SocketKit` | — | — |
| `SpeechRecognizerPermission` | `PooTools/PToolsPermissionCore` | — | `SpeechPremission` | — | — |
| `SpeedPanel` | `PooTools/Core` | — | `SpeedPanel` | — | — |
| `StepCount` | `PooTools/Core`, `PooTools/HealthPermission` | — | `HealthKit` | HealthKit | — |
| `Stepper` | `PooTools/Core` | — | `Stepper` | — | — |
| `Symbols` | — | — | `PToolsSymbols` | Foundation, OSLog, UIKit | PooToolsSymbolsResources |
| `Tabbar` | `PooTools/Core` | — | — | — | — |
| `Telephony` | `PooTools/Core` | — | `CallMessageMail` | CoreTelephony, MessageUI, WebKit | — |
| `TipsView` | `PooTools/Core` | — | `TipsView` | — | — |
| `TrackingPermission` | `PooTools/PToolsPermissionCore` | — | `TrackingPermission` | — | — |
| `VideoCache` | `PooTools/Core` | `KTVHTTPCache` | — | — | — |
| `VideoEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/Loading`, `PooTools/MediaCore`, `PooTools/ProgressBar`, `PooTools/Symbols` | — | `VideoEditor` | — | — |
| `Vision` | `PooTools/Core` | — | `Vision` | — | — |
| `WebKit` | `PooTools/Core` | — | `WebKit` | — | — |
| `WhatsNewsKit` | `PooTools/Core` | — | `WhatsNewsKit` | — | — |
| `ZipArchive` | `PooTools/Core` | `SSZipArchive` | — | — | — |
| `iOS17Tips` | `PooTools/Core` | — | `iOS17Tips` | — | — |

## Notes

- This report parses the checked-in podspec and does not resolve or change external Pods.
- `PooTools/Core` is represented by its complete source-directory list because it is the default subspec boundary.
- Legacy spelling differences remain visible so the parity gate can classify them instead of silently hiding them.
