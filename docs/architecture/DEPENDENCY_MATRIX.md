<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/generate_dependency_matrix.rb
Source revision: 87204b75bb73c4f90cdbc528ce371b8b20b933a9
Generated at: 2026-09-22T03:45:20Z
Version source: 5.20.0
-->

# Direct Dependency Matrix

This matrix records direct dependencies only. Transitive dependencies remain owned by the resolved package graphs.

| Module | Direct internal dependencies | Direct third-party dependencies | Can remove | 6.0 decision |
| --- | --- | --- | --- | --- |
| `Appz` | `Core` | `Appz` | 6.0 review | Keep; review direct drift |
| `BankCard` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `BilogyID` | `BioID`, `Core`, `FaceIDPermission`, `KeyChain`, `PTFaceIDPermission`, `ptools` | — | No direct third-party dependency | Deprecate alias |
| `BluetoothPermission` | `Core`, `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Calendar` | `CalendarPermission`, `Core`, `PTCalendarPermission`, `PTRemindersPermission`, `RemindersPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `CalendarPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `CameraPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `CheckBox` | — | — | No direct third-party dependency | Keep; review direct drift |
| `CheckDirtyWord` | — | — | No direct third-party dependency | Keep; review direct drift |
| `CheckUpdate` | `NetWork`, `PooToolsNetWork` | `SwiftJWT` | 6.0 review | Keep; review direct drift |
| `ChinesePinyin` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Circle` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `CodeView` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Contact` | `ContactsPermission`, `Core`, `PTContactsPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `ContactsPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Core` | `Logging`, `PToolsCore`, `PToolsLogging`, `PToolsPermissionCore`, `PToolsUIFoundation` | `AttributedString`, `CocoaLumberjack/Swift`, `CocoaLumberjackSwift`, `DeviceKit`, `IQKeyboardManagerSwift`, `IQKeyboardToolbarManager`, `KakaJSON`, `Kingfisher`, `Lottie`, `NotificationBannerSwift`, `SafeSFSymbols`, `SmartCodable`, `SmartCodable/Inherit`, `SnapKit`, `SwiftDate`, `SwifterSwift`, `lottie-ios` | 6.0 review | Keep; review direct drift |
| `Country` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `CustomerLabel` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `CustomerNumberKeyboard` | `Core`, `ptools` | — | No direct third-party dependency | Deprecate alias |
| `DEBUG` | `Core`, `NetWork`, `PDF`, `PooToolsNetWork`, `PooToolsPDF`, `PooToolsSearchBar`, `PooToolsShare`, `SearchBar`, `Share`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `DEBUG_TrackingEyes` | `CameraPermission`, `Core`, `DEBUG`, `PTCameraPermission`, `PooToolsDEBUG`, `ptools` | — | No direct third-party dependency | Deprecate alias |
| `DataEncrypt` | `Core`, `ptools` | `CryptoSwift` | 6.0 review | Keep; review direct drift |
| `FaceIDPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `FilterCamera` | `CameraPermission`, `Core`, `HarbethKit`, `MediaViewer`, `MicPermission` | — | No direct third-party dependency | Keep; review direct drift |
| `Flag` | `Core` | `FlagKit` | 6.0 review | Keep; review direct drift |
| `GCDWebServer` | `Core` | `GCDWebServer`, `GCDWebServer/WebUploader` | 6.0 review | Keep; review direct drift |
| `Guide` | `Core`, `PageControl`, `PooToolsPageControl`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `HandSign` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `HarbethKit` | `CameraPermission`, `Core`, `PTCameraPermission`, `ptools` | `Harbeth` | 6.0 review | Keep; review direct drift |
| `HealthPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `HeartRate` | `CameraPermission`, `Core`, `PTCameraPermission`, `ptools` | `Lottie`, `lottie-ios` | 6.0 review | Keep; review direct drift |
| `Hud` | `Core`, `PooToolsProgressBar`, `ProgressBar`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `IAP` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `ImageEditor` | `Core`, `HarbethKit`, `MediaCore`, `PhotoPicker`, `PooToolsHarbethKit`, `PooToolsMediaCore`, `PooToolsPhotoPicker`, `ptools` | `Harbeth` | 6.0 review | Keep; review direct drift |
| `ImagePicker` | `CameraPermission`, `Core`, `PTCameraPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Input` | `Core`, `ptools` | `PhoneNumberKit` | 6.0 review | Keep; review direct drift |
| `InputAll` | `Appz`, `BankCard`, `BilogyID`, `Calendar`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `Flag`, `GCDWebServer`, `Guide`, `HarbethKit`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `Input`, `Instructions`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `MediaViewer`, `MessageKit`, `Motion`, `NetWork`, `NotificationBanner`, `OSSKitSpeech`, `PDF`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `PopoverKit`, `ProgressBar`, `RateView`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `SecuritySuite`, `Segmented`, `Share`, `Slider`, `SmartScreenshot`, `SocketKit`, `Stepper`, `Tabbar`, `Telephony`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `ZipArchive`, `iOS17Tips` | — | No direct third-party dependency | Keep; review direct drift |
| `Instructions` | `Core` | `Instructions` | 6.0 review | Keep; review direct drift |
| `KeyChain` | — | — | No direct third-party dependency | Keep; review direct drift |
| `LaunchTimeProfiler` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Layout` | `Core`, `ptools` | `CollectionViewPagingLayout` | 6.0 review | Keep; review direct drift |
| `LivePhoto` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Loading` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Location` | `Core`, `LocationPermission`, `PTLocationPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `LocationPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Logging` | — | — | No direct third-party dependency | Keep; review direct drift |
| `MXMetricManagerKit` | `Core` | — | No direct third-party dependency | Keep; review direct drift |
| `MediaCore` | — | — | No direct third-party dependency | Keep; review direct drift |
| `MediaViewer` | `Core`, `LivePhoto`, `MediaCore`, `PageControl`, `PooToolsLivePhoto`, `PooToolsMediaCore`, `PooToolsPageControl`, `PooToolsProgressBar`, `ProgressBar`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `MeidaPermission` | `MediaPermission`, `PToolsPermissionCore` | — | No direct third-party dependency | Deprecate alias |
| `MessageKit` | `Core`, `CustomerLabel`, `PooToolsCustomerLabel`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `MicPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Motion` | `Core`, `MotionPermission`, `PTMotionPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `MotionPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `NFCKit` | `Core` | — | No direct third-party dependency | Keep; review direct drift |
| `NetWork` | `Core`, `Loading`, `Network`, `PToolsCore`, `PooToolsLoading`, `ptools` | `Alamofire` | 6.0 review | Deprecate alias |
| `NetworkSpeedTest` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `NotificationBanner` | `Core` | `NotificationBannerSwift` | 6.0 review | Keep; review direct drift |
| `NotificationPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `OSSKitSpeech` | `Core`, `PTSpeechPermission`, `SpeechRecognizerPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `PDF` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `PToolsCore` | — | — | No direct third-party dependency | Keep; review direct drift |
| `PToolsPermissionCore` | — | — | No direct third-party dependency | Keep; review direct drift |
| `PToolsPermissionUI` | `PToolsPermissionCore`, `PToolsUIFoundation` | — | No direct third-party dependency | Keep; review direct drift |
| `PToolsUIFoundation` | `PToolsCore` | `SnapKit` | 6.0 review | Keep; review direct drift |
| `PageControl` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `PagingControl` | `Core`, `ptools` | `JXPagingView`, `JXPagingView/Paging`, `JXSegmentedView` | 6.0 review | Keep; review direct drift |
| `PhoneInfo` | — | — | No direct third-party dependency | Keep; review direct drift |
| `PhotoPicker` | `Core`, `ImagePicker`, `Loading`, `MediaCore`, `PTCameraPermission`, `PooToolsImagePicker`, `PooToolsLoading`, `PooToolsMediaCore`, `ptools` | `Kakapos` | 6.0 review | Keep; review direct drift |
| `Picker` | `Core`, `ptools` | `SnapKit`, `SwifterSwift` | 6.0 review | Keep; review direct drift |
| `Ping` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `PopoverKit` | `Core` | `Popovers` | 6.0 review | Keep; review direct drift |
| `ProgressBar` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `RateView` | `PToolsUIFoundation` | `SnapKit`, `SwifterSwift` | 6.0 review | Keep; review direct drift |
| `RemindersPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Router` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `SVG` | `Core`, `ptools` | `Kingfisher`, `PocketSVG`, `Protobuf`, `SVGAPlayer` | 6.0 review | Keep; review direct drift |
| `ScanQRCode` | `CameraPermission`, `Core`, `PTCameraPermission`, `PhotoPicker`, `PooToolsImagePicker`, `PooToolsPhotoPicker`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `ScrollBanner` | `Core`, `PageControl`, `PooToolsPageControl`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Search` | `Core`, `PooToolsSearchBar`, `SearchBar`, `ptools` | `AttributedString` | 6.0 review | Keep; review direct drift |
| `SearchBar` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Security` | — | — | No direct third-party dependency | Keep; review direct drift |
| `SecuritySuite` | `Core` | `IOSSecuritySuite` | 6.0 review | Keep; review direct drift |
| `Segmented` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Share` | `CustomerLabel`, `PooToolsCustomerLabel` | — | No direct third-party dependency | Keep; review direct drift |
| `SiriPermission` | `Core`, `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `Slider` | `PToolsUIFoundation` | `SnapKit` | 6.0 review | Keep; review direct drift |
| `SmartScreenshot` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `SocketKit` | `Core`, `ptools` | `SocketRocket` | 6.0 review | Keep; review direct drift |
| `SpeechRecognizerPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Deprecate alias |
| `SpeedPanel` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `StepCount` | `Core`, `HealthPermission`, `PTHealthPermission`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Stepper` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `Tabbar` | `Core` | — | No direct third-party dependency | Keep; review direct drift |
| `Telephony` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `TipsView` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `TrackingPermission` | `PToolsPermissionCore` | — | No direct third-party dependency | Keep; review direct drift |
| `VideoCache` | `Core` | `KTVHTTPCache` | 6.0 review | Keep; review direct drift |
| `VideoEditor` | `Core`, `HarbethKit`, `Loading`, `MediaCore`, `PooToolsHarbethKit`, `PooToolsLoading`, `PooToolsMediaCore`, `PooToolsProgressBar`, `ProgressBar`, `ptools` | `Harbeth` | 6.0 review | Keep; review direct drift |
| `Vision` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `WebKit` | `Core` | — | No direct third-party dependency | Keep; review direct drift |
| `WhatsNewsKit` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |
| `ZipArchive` | `Core` | `SSZipArchive` | 6.0 review | Keep; review direct drift |
| `iOS17Tips` | `Core`, `ptools` | — | No direct third-party dependency | Keep; review direct drift |

## Review rules

- A dependency is removable only after public API, runtime behavior and both package managers are verified.
- Third-party entries must not leak through new public API types.
- Changes to this matrix must be accompanied by a package graph report and an owner/expiration entry when parity intentionally differs.
