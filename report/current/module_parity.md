<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_module_parity.sh
Source revision: 7ee78f9cf3dde1cb7f796febd2d7aa45d024ef9d
Generated at: 2026-09-28T14:24:29Z
-->

# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `91ed851f55bd3779906738d99589edcc75ba0e74d1597edbf1e1810e70cfb0f3`
- Matched modules: `118`
- SwiftPM-only modules: `1`
- CocoaPods-only modules: `15`
- Source-directory drift: `1`
- Dependency drift: `22`
- Swift setting / macro drift: `51`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `Accessibility`, `Activities`, `AppIntents`, `Audio`, `BackgroundTasks`, `BankCard`, `Banner`, `BilogyID`, `Bluetooth`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Configuration`, `Connectivity`, `Contact`, `ContactsPermission`, `ContentState`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `DeepLink`, `Device`, `Documents`, `FaceIDPermission`, `Feedback`, `Form`, `Guide`, `HTTPFilePortal`, `HTTPServer`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `Instructions`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `Logging`, `MediaCore`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `Notifications`, `OSSKitSpeech`, `Overlay`, `PDF`, `PToolsCore`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `Popover`, `ProgressBar`, `RateView`, `RemindersPermission`, `RouteCore`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `Segmented`, `Share`, `Simulation`, `SimulationCore`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `StepCount`, `Stepper`, `Storage`, `StorageCore`, `Symbols`, `Telephony`, `Theme`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `WidgetCore`, `iOS17Tips` |
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
- `Configuration` / `internal_dependencies`: SPM=["Storage", "StorageCore"]; CocoaPods=["Storage"]
- `Core` / `internal_dependencies`: SPM=["Device", "Logging", "PToolsCore", "PToolsDate", "PToolsPermissionCore", "PToolsUIFoundation", "Symbols"]; CocoaPods=["Date", "Device", "Logging", "PToolsCore", "PToolsUIFoundation", "Symbols"]
- `Core` / `third_party_dependencies`: SPM=["IQKeyboardManager", "KakaJSON", "Kingfisher", "SmartCodable", "SnapKit", "lottie-ios"]; CocoaPods=["IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "KakaJSON", "Kingfisher", "SmartCodable", "SmartCodable/Inherit", "SnapKit", "lottie-ios"]
- `Form` / `internal_dependencies`: SPM=["Accessibility", "CheckBox", "ContentState", "Core", "PToolsCore", "Picker", "Slider", "Theme"]; CocoaPods=["Accessibility", "CheckBox", "ContentState", "Core", "Input", "PToolsCore", "Picker", "Slider", "Stepper", "Theme"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `Instructions` / `internal_dependencies`: SPM=["Overlay"]; CocoaPods=["Core", "Overlay"]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["MeidaPermission"]
- `NetWork` / `internal_dependencies`: SPM=["Core", "Loading", "PToolsCore"]; CocoaPods=["Core", "Loading"]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]; CocoaPods=["Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Popover` / `internal_dependencies`: SPM=["Overlay", "PToolsCore", "Symbols"]; CocoaPods=["Overlay", "Symbols"]
- `RateView` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `SiriPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `Slider` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `TipsView` / `internal_dependencies`: SPM=["Core", "Overlay"]; CocoaPods=["Core"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `WidgetCore` / `internal_dependencies`: SPM=["DeepLink", "RouteCore", "Storage", "StorageCore"]; CocoaPods=["DeepLink", "RouteCore", "Storage"]

### Swift settings and macros

- `Accessibility`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Activities`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_ACTIVITIES", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `AppIntents`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_APPINTENTS", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `Audio`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_AUDIO", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `BackgroundTasks`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_BACKGROUND_TASKS", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `Banner`: SPM={"defines"=>["POOTOOLS_BANNER", "POOTOOLS_COCOAPODS"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_BANNER", "POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `Bluetooth`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `BluetoothPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH"], "upcoming_features"=>[]}
- `CalendarPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR"], "upcoming_features"=>[]}
- `CameraPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA"], "upcoming_features"=>[]}
- `Configuration`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_CONFIGURATION"], "upcoming_features"=>[]}
- `Connectivity`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_CONNECTIVITY"], "upcoming_features"=>[]}
- `ContactsPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS"], "upcoming_features"=>[]}
- `ContentState`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_COCOAPODS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_PICKER", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_UIFOUNDATION"], "upcoming_features"=>[]}
- `DeepLink`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_DEEPLINK"], "upcoming_features"=>[]}
- `Device`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Documents`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `FaceIDPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION"], "upcoming_features"=>[]}
- `Feedback`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_FEEDBACK"], "upcoming_features"=>[]}
- `Form`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HTTPFilePortal`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HTTPServer`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HealthPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH"], "upcoming_features"=>[]}
- `Instructions`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>[]}
- `LocationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION"], "upcoming_features"=>[]}
- `Logging`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_LOGGING"], "upcoming_features"=>[]}
- `MediaCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MeidaPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MicPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION"], "upcoming_features"=>[]}
- `Notifications`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_NOTIFICATIONS"], "upcoming_features"=>[]}
- `Overlay`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>[]}
- `PToolsCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionUI`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsUIFoundation`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Popover`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>[]}
- `RemindersPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS"], "upcoming_features"=>[]}
- `RouteCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_ROUTE_CORE"], "upcoming_features"=>[]}
- `Simulation`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `SimulationCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `SiriPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI"], "upcoming_features"=>[]}
- `SpeechRecognizerPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH"], "upcoming_features"=>[]}
- `Storage`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_STORAGE"], "upcoming_features"=>[]}
- `StorageCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_STORAGE_CORE"], "upcoming_features"=>[]}
- `Symbols`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Theme`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `TrackingPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING"], "upcoming_features"=>[]}
- `WidgetCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_WIDGET_CORE"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
