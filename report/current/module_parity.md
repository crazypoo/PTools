<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_module_parity.sh
Source revision: ce03fbefe62ed5b0729949386a7c4101dbf28d25
Generated at: 2026-09-27T13:57:07Z
-->

# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `82d85d47d75a0b8ba3837b50bda0b06fd8ce78f9d163c0af916c23884f9f0893`
- Matched modules: `96`
- SwiftPM-only modules: `1`
- CocoaPods-only modules: `15`
- Source-directory drift: `1`
- Dependency drift: `18`
- Swift setting / macro drift: `29`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `BankCard`, `Banner`, `BilogyID`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Contact`, `ContactsPermission`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `FaceIDPermission`, `Guide`, `HTTPFilePortal`, `HTTPServer`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `Instructions`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `Logging`, `MediaCore`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `OSSKitSpeech`, `Overlay`, `PDF`, `PToolsCore`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `Popover`, `ProgressBar`, `RateView`, `RemindersPermission`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `Segmented`, `Share`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `StepCount`, `Stepper`, `Symbols`, `Telephony`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `iOS17Tips` |
| SwiftPM only | `PToolsDate` |
| CocoaPods only | `Appz`, `Date`, `FilterCamera`, `Flag`, `GCDWebServer`, `InputAll`, `MXMetricManagerKit`, `NFCKit`, `NotificationBanner`, `PopoverKit`, `SecuritySuite`, `Tabbar`, `VideoCache`, `WebKit`, `ZipArchive` |

## Drift details

The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review.

### Source directories

- `MeidaPermission`: SPM=["MeidaLibraryPermission"]; CocoaPods=[]

### Dependencies

- `BilogyID` / `internal_dependencies`: SPM=["Core", "FaceIDPermission"]; CocoaPods=["Core", "FaceIDPermission", "KeyChain"]
- `BluetoothPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `Core` / `internal_dependencies`: SPM=["Logging", "PToolsCore", "PToolsDate", "PToolsPermissionCore", "PToolsUIFoundation", "Symbols"]; CocoaPods=["Date", "Logging", "PToolsCore", "PToolsUIFoundation", "Symbols"]
- `Core` / `third_party_dependencies`: SPM=["DeviceKit", "IQKeyboardManager", "KakaJSON", "Kingfisher", "SmartCodable", "SnapKit", "lottie-ios"]; CocoaPods=["DeviceKit", "IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "KakaJSON", "Kingfisher", "SmartCodable", "SmartCodable/Inherit", "SnapKit", "lottie-ios"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `Instructions` / `internal_dependencies`: SPM=["Overlay"]; CocoaPods=["Core", "Overlay"]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["MeidaPermission"]
- `NetWork` / `internal_dependencies`: SPM=["Core", "Loading", "PToolsCore"]; CocoaPods=["Core", "Loading"]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]; CocoaPods=["Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `RateView` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `SiriPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `Slider` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `TipsView` / `internal_dependencies`: SPM=["Core", "Overlay"]; CocoaPods=["Core"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]

### Swift settings and macros

- `Banner`: SPM={"defines"=>["POOTOOLS_BANNER", "POOTOOLS_COCOAPODS"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_BANNER", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `BluetoothPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH"], "upcoming_features"=>[]}
- `CalendarPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR"], "upcoming_features"=>[]}
- `CameraPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA"], "upcoming_features"=>[]}
- `ContactsPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS"], "upcoming_features"=>[]}
- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_COCOAPODS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_PICKER", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_UIFOUNDATION"], "upcoming_features"=>[]}
- `FaceIDPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION"], "upcoming_features"=>[]}
- `HTTPFilePortal`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HTTPServer`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HealthPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH"], "upcoming_features"=>[]}
- `Instructions`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>[]}
- `LocationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION"], "upcoming_features"=>[]}
- `Logging`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_LOGGING"], "upcoming_features"=>[]}
- `MediaCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MeidaPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MicPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION"], "upcoming_features"=>[]}
- `Overlay`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>[]}
- `PToolsCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionCore`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionUI`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsUIFoundation`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Popover`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>[]}
- `RemindersPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS"], "upcoming_features"=>[]}
- `SiriPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI"], "upcoming_features"=>[]}
- `SpeechRecognizerPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH"], "upcoming_features"=>[]}
- `Symbols`: SPM={"defines"=>[], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `TrackingPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
