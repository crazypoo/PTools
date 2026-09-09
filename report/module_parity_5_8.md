# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `ec77784cb33174c7b6bf327ca6370a3ab8c41de59732d69ddeea2474929a7357`
- Matched modules: `81`
- SwiftPM-only modules: `0`
- CocoaPods-only modules: `15`
- Source-directory drift: `0`
- Dependency drift: `10`
- Swift setting / macro drift: `1`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `BankCard`, `BilogyID`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Contact`, `ContactsPermission`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `FaceIDPermission`, `Guide`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `OSSKitSpeech`, `PDF`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `ProgressBar`, `RateView`, `RemindersPermission`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `SearchBar`, `Segmented`, `Share`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `StepCount`, `Stepper`, `Telephony`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `iOS17Tips` |
| SwiftPM only | — |
| CocoaPods only | `Appz`, `FilterCamera`, `Flag`, `GCDWebServer`, `InputAll`, `Instructions`, `MXMetricManagerKit`, `NFCKit`, `NotificationBanner`, `PopoverKit`, `SecuritySuite`, `Tabbar`, `VideoCache`, `WebKit`, `ZipArchive` |

## Drift details

The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review.

### Source directories

- None

### Dependencies

- `BilogyID` / `internal_dependencies`: SPM=["Core", "FaceIDPermission"]; CocoaPods=["Core", "FaceIDPermission", "KeyChain"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `Core` / `third_party_dependencies`: SPM=["AttributedString", "CocoaLumberjack", "DeviceKit", "FlagKit", "IOSSecuritySuite", "IQKeyboardManager", "Instructions", "KakaJSON", "Kingfisher", "NotificationBanner", "Popovers", "SafeSFSymbols", "SmartCodable", "SnapKit", "SwiftDate", "SwifterSwift", "ZipArchive", "lottie-ios"]; CocoaPods=["AttributedString", "CocoaLumberjack/Swift", "DeviceKit", "IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "KakaJSON", "Kingfisher", "SafeSFSymbols", "SmartCodable", "SmartCodable/Inherit", "SnapKit", "SwiftDate", "SwifterSwift", "lottie-ios"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `PagingControl` / `third_party_dependencies`: SPM=["JXPagingView", "JXSegmentedView"]; CocoaPods=["JXPagingView/Paging", "JXSegmentedView"]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "NetWork"]; CocoaPods=["Core", "ImagePicker", "Loading", "NetWork"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit", "SwifterSwift"]; CocoaPods=[]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]

### Swift settings and macros

- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_CGDWEBSERVER", "POOTOOLS_COCOAPODS", "POOTOOLS_FLAG", "POOTOOLS_INSTRUCTIONS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_NOTIFICATIONBANNER", "POOTOOLS_PICKER", "POOTOOLS_POPOVERKIT", "POOTOOLS_SECURITYSUITE", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE", "POOTOOLS_ZIPARCHINE"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
