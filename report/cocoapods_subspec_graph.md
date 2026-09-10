# CocoaPods Subspec Graph

- Schema: `1`
- Podspec: `PooTools` `5.9.3`
- Default subspec: `Core`
- iOS: `17.0`
- Swift: `6.0`
- Subspec count: `96`

## Subspecs

| Subspec | Local dependencies | Third-party dependencies | Source directories | Frameworks | Resources |
| --- | --- | --- | --- | --- | --- |
| `Appz` | `PooTools/Core` | `Appz` | — | — | — |
| `BankCard` | `PooTools/Core` | — | `BankCard` | — | — |
| `BilogyID` | `PooTools/Core`, `PooTools/FaceIDPermission`, `PooTools/KeyChain` | — | `BioID` | LocalAuthentication, Security | — |
| `BluetoothPermission` | `PooTools/Core` | — | `BluetoothPermission` | — | — |
| `Calendar` | `PooTools/CalendarPermission`, `PooTools/Core`, `PooTools/RemindersPermission` | — | `Calendar` | EventKit | — |
| `CalendarPermission` | `PooTools/Core` | — | `CalendarPermission` | — | — |
| `CameraPermission` | `PooTools/Core` | — | `CameraPermission` | — | — |
| `CheckBox` | `PooTools/Core` | — | `CheckBox` | — | — |
| `CheckDirtyWord` | `PooTools/Core` | — | `CheckDirtyWord` | — | PooToolsCheckDirtyWordResource |
| `CheckUpdate` | `PooTools/NetWork` | `SwiftJWT` | `CheckUpdate` | — | — |
| `ChinesePinyin` | `PooTools/Core` | — | `Pinyin` | — | — |
| `Circle` | `PooTools/Core` | — | `Circle` | — | — |
| `CodeView` | `PooTools/Core` | — | `CodeView` | — | — |
| `Contact` | `PooTools/ContactsPermission`, `PooTools/Core` | — | `Contact` | — | — |
| `ContactsPermission` | `PooTools/Core` | — | `ContactsPermission` | — | — |
| `Core` | — | `AttributedString`, `CocoaLumberjack/Swift`, `DeviceKit`, `IQKeyboardManagerSwift`, `IQKeyboardToolbarManager`, `KakaJSON`, `Kingfisher`, `SafeSFSymbols`, `SmartCodable`, `SmartCodable/Inherit`, `SnapKit`, `SwiftDate`, `SwifterSwift`, `lottie-ios` | `ActionsheetAndAlert`, `Animation`, `AppDelegate`, `AppStore`, `ApplicationFunction`, `Badge`, `Base`, `BlackMagic`, `Blur`, `Button`, `Category`, `Colors`, `Core`, `DarkMode`, `FloatPanel`, `Font`, `Foundation`, `Language`, `Line`, `Log`, `PermissionCore`, `PhotoLibraryPermission`, `Protocol`, `Rotation`, `SideMenuControl`, `StatusBar`, `Switch`, `iCloud` | AVFoundation, AVKit, AudioToolbox, CoreFoundation, CoreText, Foundation, Photos, UIKit | PooToolsResource |
| `Country` | `PooTools/Core` | — | `Country` | — | — |
| `CustomerLabel` | `PooTools/Core` | — | `Label` | QuartzCore | — |
| `CustomerNumberKeyboard` | `PooTools/Core` | — | `Keyboard` | — | — |
| `DEBUG` | `PooTools/Core`, `PooTools/NetWork`, `PooTools/PDF`, `PooTools/SearchBar`, `PooTools/Share` | — | `DEBUGLocation`, `Debug`, `DebugCategory`, `DebugColor`, `DebugCrash`, `DebugFile`, `DebugLibs`, `DebugNetwork`, `DebugPerformance`, `DebugRuler`, `DebugUserDefault`, `DevMask`, `Inspector`, `LocalConsole`, `TouchInspector` | — | — |
| `DEBUG_TrackingEyes` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/DEBUG` | — | `WhereIsMyEye` | — | — |
| `DataEncrypt` | `PooTools/Core` | `CryptoSwift` | `AESAndDES` | — | — |
| `FaceIDPermission` | `PooTools/Core` | — | `FaceIDPermission` | — | — |
| `FilterCamera` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/MediaViewer`, `PooTools/MicPermission` | — | `FilterCamera` | — | — |
| `Flag` | `PooTools/Core` | `FlagKit` | — | — | — |
| `GCDWebServer` | `PooTools/Core` | `GCDWebServer`, `GCDWebServer/WebUploader` | — | — | — |
| `Guide` | `PooTools/Core`, `PooTools/PageControl` | — | `Guide` | — | — |
| `HandSign` | `PooTools/Core` | — | `SignView` | — | — |
| `HarbethKit` | `PooTools/CameraPermission`, `PooTools/Core` | `Harbeth` | `C7Collector` | — | — |
| `HealthPermission` | `PooTools/Core` | — | `HealthPermission` | — | — |
| `HeartRate` | `PooTools/CameraPermission`, `PooTools/Core` | `lottie-ios` | `HeartRate` | — | — |
| `Hud` | `PooTools/Core`, `PooTools/ProgressBar` | — | `Hud` | — | — |
| `IAP` | `PooTools/Core` | — | `IAP` | — | — |
| `ImageEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/PhotoPicker` | — | `ImageEditor` | — | — |
| `ImagePicker` | `PooTools/CameraPermission`, `PooTools/Core` | — | `ImagePicker` | — | — |
| `Input` | `PooTools/Core` | `PhoneNumberKit` | `Input` | — | — |
| `InputAll` | `PooTools/Appz`, `PooTools/BankCard`, `PooTools/BilogyID`, `PooTools/Calendar`, `PooTools/CheckBox`, `PooTools/CheckDirtyWord`, `PooTools/CheckUpdate`, `PooTools/ChinesePinyin`, `PooTools/Circle`, `PooTools/CodeView`, `PooTools/Core`, `PooTools/Country`, `PooTools/CustomerLabel`, `PooTools/CustomerNumberKeyboard`, `PooTools/DEBUG`, `PooTools/DEBUG_TrackingEyes`, `PooTools/DataEncrypt`, `PooTools/Flag`, `PooTools/GCDWebServer`, `PooTools/Guide`, `PooTools/HarbethKit`, `PooTools/HeartRate`, `PooTools/Hud`, `PooTools/IAP`, `PooTools/ImageEditor`, `PooTools/Input`, `PooTools/Instructions`, `PooTools/KeyChain`, `PooTools/LaunchTimeProfiler`, `PooTools/Layout`, `PooTools/LivePhoto`, `PooTools/Loading`, `PooTools/Location`, `PooTools/MediaViewer`, `PooTools/MessageKit`, `PooTools/Motion`, `PooTools/NetWork`, `PooTools/NotificationBanner`, `PooTools/OSSKitSpeech`, `PooTools/PDF`, `PooTools/PageControl`, `PooTools/PagingControl`, `PooTools/PhoneInfo`, `PooTools/PhotoPicker`, `PooTools/Picker`, `PooTools/Ping`, `PooTools/PopoverKit`, `PooTools/ProgressBar`, `PooTools/RateView`, `PooTools/Router`, `PooTools/SVG`, `PooTools/ScanQRCode`, `PooTools/ScrollBanner`, `PooTools/SearchBar`, `PooTools/SecuritySuite`, `PooTools/Segmented`, `PooTools/Share`, `PooTools/Slider`, `PooTools/SmartScreenshot`, `PooTools/SocketKit`, `PooTools/Stepper`, `PooTools/Tabbar`, `PooTools/Telephony`, `PooTools/VideoEditor`, `PooTools/Vision`, `PooTools/WhatsNewsKit`, `PooTools/ZipArchive`, `PooTools/iOS17Tips` | — | — | — | — |
| `Instructions` | `PooTools/Core` | `Instructions` | — | — | — |
| `KeyChain` | `PooTools/Core` | — | `KeyChain` | — | — |
| `LaunchTimeProfiler` | `PooTools/Core` | — | `LaunchTimeProfiler` | — | — |
| `Layout` | `PooTools/Core` | `CollectionViewPagingLayout` | `Layout` | — | — |
| `LivePhoto` | `PooTools/Core` | — | `LivePhoto` | — | — |
| `Loading` | `PooTools/Core` | — | `Loading` | — | — |
| `Location` | `PooTools/Core`, `PooTools/LocationPermission` | — | `Location` | CoreLocation | — |
| `LocationPermission` | `PooTools/Core` | — | `LocationPermission` | — | — |
| `MXMetricManagerKit` | `PooTools/Core` | — | `MXMetricKitManager` | — | — |
| `MediaViewer` | `PooTools/Core`, `PooTools/LivePhoto`, `PooTools/NetWork`, `PooTools/PageControl`, `PooTools/ProgressBar` | — | `MediaViewer` | Photos | — |
| `MeidaPermission` | `PooTools/Core` | — | `MeidaLibraryPermission` | — | — |
| `MessageKit` | `PooTools/Core`, `PooTools/CustomerLabel` | — | `MessageKit` | — | — |
| `MicPermission` | `PooTools/Core` | — | `MicPermission` | — | — |
| `Motion` | `PooTools/Core`, `PooTools/MotionPermission` | — | `Motion` | CoreMotion | — |
| `MotionPermission` | `PooTools/Core` | — | `MotionPermission` | — | — |
| `NFCKit` | `PooTools/Core` | — | `NFC` | — | — |
| `NetWork` | `PooTools/Core`, `PooTools/Loading` | `Alamofire` | `NetWork` | — | — |
| `NetworkSpeedTest` | `PooTools/Core` | — | `NetworkSpeedTest` | — | — |
| `NotificationBanner` | `PooTools/Core` | `NotificationBannerSwift` | — | — | — |
| `NotificationPermission` | `PooTools/Core` | — | `NotificationPermission` | — | — |
| `OSSKitSpeech` | `PooTools/Core`, `PooTools/SpeechRecognizerPermission` | — | `OSSKit` | Speech | — |
| `PDF` | `PooTools/Core` | — | `PDF` | — | — |
| `PageControl` | `PooTools/Core` | — | `PageControl` | — | — |
| `PagingControl` | `PooTools/Core` | `JXPagingView/Paging`, `JXSegmentedView` | `SegmentControl` | — | — |
| `PhoneInfo` | `PooTools/Core` | — | `PhoneInfo` | Security | — |
| `PhotoPicker` | `PooTools/Core`, `PooTools/ImagePicker`, `PooTools/Loading`, `PooTools/NetWork` | `Kakapos` | `PhotoPicker` | — | — |
| `Picker` | `PooTools/Core` | — | `Picker` | — | — |
| `Ping` | `PooTools/Core` | — | `Ping` | — | — |
| `PopoverKit` | `PooTools/Core` | `Popovers` | — | — | — |
| `ProgressBar` | `PooTools/Core` | — | `ProgressBar` | — | — |
| `RateView` | `PooTools/Core` | — | `RateView` | — | — |
| `RemindersPermission` | `PooTools/Core` | — | `RemindersPermission` | — | — |
| `Router` | `PooTools/Core` | — | `Router` | — | — |
| `SVG` | `PooTools/Core` | `PocketSVG`, `Protobuf`, `SVGAPlayer` | `KingfisherSVG` | — | — |
| `ScanQRCode` | `PooTools/CameraPermission`, `PooTools/Core`, `PooTools/PhotoPicker` | — | `QRCodeScan` | — | — |
| `ScrollBanner` | `PooTools/Core`, `PooTools/PageControl` | — | `ScrollBanner` | — | — |
| `SearchBar` | `PooTools/Core` | — | `SearchBar` | — | — |
| `SecuritySuite` | `PooTools/Core` | `IOSSecuritySuite` | — | — | — |
| `Segmented` | `PooTools/Core` | — | `Segmented` | — | — |
| `Share` | `PooTools/CustomerLabel` | — | `Share` | — | — |
| `SiriPermission` | `PooTools/Core` | — | `SiriPermission` | — | — |
| `Slider` | `PooTools/Core` | — | `Slider` | — | — |
| `SmartScreenshot` | `PooTools/Core` | — | `ScreenShot` | — | — |
| `SocketKit` | `PooTools/Core` | `SocketRocket` | `SocketKit` | — | — |
| `SpeechRecognizerPermission` | `PooTools/Core` | — | `SpeechPremission` | — | — |
| `SpeedPanel` | `PooTools/Core` | — | `SpeedPanel` | — | — |
| `StepCount` | `PooTools/Core`, `PooTools/HealthPermission` | — | `HealthKit` | HealthKit | — |
| `Stepper` | `PooTools/Core` | — | `Stepper` | — | — |
| `Tabbar` | `PooTools/Core` | — | — | — | — |
| `Telephony` | `PooTools/Core` | — | `CallMessageMail` | CoreTelephony, MessageUI, WebKit | — |
| `TipsView` | `PooTools/Core` | — | `TipsView` | — | — |
| `TrackingPermission` | `PooTools/Core` | — | `TrackingPermission` | — | — |
| `VideoCache` | `PooTools/Core` | `KTVHTTPCache` | — | — | — |
| `VideoEditor` | `PooTools/Core`, `PooTools/HarbethKit`, `PooTools/Loading`, `PooTools/ProgressBar` | — | `VideoEditor` | — | — |
| `Vision` | `PooTools/Core` | — | `Vision` | — | — |
| `WebKit` | `PooTools/Core` | — | `WebKit` | — | — |
| `WhatsNewsKit` | `PooTools/Core` | — | `WhatsNewsKit` | — | — |
| `ZipArchive` | `PooTools/Core` | `SSZipArchive` | — | — | — |
| `iOS17Tips` | `PooTools/Core` | — | `iOS17Tips` | — | — |

## Notes

- This report parses the checked-in podspec and does not resolve or change external Pods.
- `PooTools/Core` is represented by its complete source-directory list because it is the default subspec boundary.
- Legacy spelling differences remain visible so the parity gate can classify them instead of silently hiding them.
