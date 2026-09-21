<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_module_parity.sh
Source revision: 8e23da3b11c66363dcaa2c0e1a4f10eec6b97ee7
Generated at: 2026-09-21T02:12:51Z
-->

# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `c065ae0c4df183a145885e991f5ad92df0b26838824dc6c2ed97bd2f9738b277`
- Matched modules: `88`
- SwiftPM-only modules: `0`
- CocoaPods-only modules: `15`
- Source-directory drift: `1`
- Dependency drift: `17`
- Swift setting / macro drift: `21`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `BankCard`, `BilogyID`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Contact`, `ContactsPermission`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `FaceIDPermission`, `Guide`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `MediaCore`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `OSSKitSpeech`, `PDF`, `PToolsCore`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `ProgressBar`, `RateView`, `RemindersPermission`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `Segmented`, `Share`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `StepCount`, `Stepper`, `Telephony`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `iOS17Tips` |
| SwiftPM only | — |
| CocoaPods only | `Appz`, `FilterCamera`, `Flag`, `GCDWebServer`, `InputAll`, `Instructions`, `MXMetricManagerKit`, `NFCKit`, `NotificationBanner`, `PopoverKit`, `SecuritySuite`, `Tabbar`, `VideoCache`, `WebKit`, `ZipArchive` |

## Drift details

The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review.

### Source directories

- `MeidaPermission`: SPM=["MeidaLibraryPermission"]; CocoaPods=[]

### Dependencies

- `BilogyID` / `internal_dependencies`: SPM=["Core", "FaceIDPermission"]; CocoaPods=["Core", "FaceIDPermission", "KeyChain"]
- `BluetoothPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `Core` / `internal_dependencies`: SPM=["PToolsCore", "PToolsPermissionCore", "PToolsUIFoundation"]; CocoaPods=["PToolsCore", "PToolsUIFoundation"]
- `Core` / `third_party_dependencies`: SPM=["AttributedString", "CocoaLumberjack", "DeviceKit", "IQKeyboardManager", "KakaJSON", "Kingfisher", "NotificationBanner", "SafeSFSymbols", "SmartCodable", "SnapKit", "SwiftDate", "SwifterSwift", "lottie-ios"]; CocoaPods=["AttributedString", "CocoaLumberjack/Swift", "DeviceKit", "IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "KakaJSON", "Kingfisher", "SafeSFSymbols", "SmartCodable", "SmartCodable/Inherit", "SnapKit", "SwiftDate", "SwifterSwift", "lottie-ios"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["MeidaPermission"]
- `NetWork` / `internal_dependencies`: SPM=["Core", "Loading", "PToolsCore"]; CocoaPods=["Core", "Loading"]
- `PagingControl` / `third_party_dependencies`: SPM=["JXPagingView", "JXSegmentedView"]; CocoaPods=["JXPagingView/Paging", "JXSegmentedView"]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "MediaCore"]; CocoaPods=["Core", "ImagePicker", "Loading", "MediaCore"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit", "SwifterSwift"]; CocoaPods=[]
- `RateView` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `SiriPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `Slider` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]

### Swift settings and macros

- `BluetoothPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH"], "upcoming_features"=>[]}
- `CalendarPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR"], "upcoming_features"=>[]}
- `CameraPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA"], "upcoming_features"=>[]}
- `ContactsPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS"], "upcoming_features"=>[]}
- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_CGDWEBSERVER", "POOTOOLS_COCOAPODS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_NOTIFICATIONBANNER", "POOTOOLS_PICKER", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_UIFOUNDATION"], "upcoming_features"=>[]}
- `FaceIDPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION"], "upcoming_features"=>[]}
- `HealthPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH"], "upcoming_features"=>[]}
- `LocationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION"], "upcoming_features"=>[]}
- `MediaCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MeidaPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MicPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION"], "upcoming_features"=>[]}
- `PToolsCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionUI`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsUIFoundation`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `RemindersPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS"], "upcoming_features"=>[]}
- `SiriPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI"], "upcoming_features"=>[]}
- `SpeechRecognizerPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH"], "upcoming_features"=>[]}
- `TrackingPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
