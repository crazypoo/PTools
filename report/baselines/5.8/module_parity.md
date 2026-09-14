# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `48e12f318d897b5682f3b470b5b3027c307528f752832423a03eb4ea0563e60b`
- Matched modules: `81`
- SwiftPM-only modules: `4`
- CocoaPods-only modules: `15`
- Source-directory drift: `0`
- Dependency drift: `27`
- Swift setting / macro drift: `16`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `BankCard`, `BilogyID`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Contact`, `ContactsPermission`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `FaceIDPermission`, `Guide`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `OSSKitSpeech`, `PDF`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `ProgressBar`, `RateView`, `RemindersPermission`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `SearchBar`, `Segmented`, `Share`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `StepCount`, `Stepper`, `Telephony`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `iOS17Tips` |
| SwiftPM only | `PToolsCore`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation` |
| CocoaPods only | `Appz`, `FilterCamera`, `Flag`, `GCDWebServer`, `InputAll`, `Instructions`, `MXMetricManagerKit`, `NFCKit`, `NotificationBanner`, `PopoverKit`, `SecuritySuite`, `Tabbar`, `VideoCache`, `WebKit`, `ZipArchive` |

## Drift details

The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review.

### Source directories

- None

### Dependencies

- `BilogyID` / `internal_dependencies`: SPM=["Core", "FaceIDPermission"]; CocoaPods=["Core", "FaceIDPermission", "KeyChain"]
- `BluetoothPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CalendarPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CameraPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `ContactsPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `Core` / `internal_dependencies`: SPM=["PToolsCore", "PToolsPermissionCore", "PToolsUIFoundation"]; CocoaPods=[]
- `Core` / `third_party_dependencies`: SPM=["AttributedString", "CocoaLumberjack", "DeviceKit", "FlagKit", "IOSSecuritySuite", "IQKeyboardManager", "Instructions", "KakaJSON", "Kingfisher", "NotificationBanner", "Popovers", "SafeSFSymbols", "SmartCodable", "SnapKit", "SwiftDate", "SwifterSwift", "ZipArchive", "lottie-ios"]; CocoaPods=["AttributedString", "CocoaLumberjack/Swift", "DeviceKit", "IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "KakaJSON", "Kingfisher", "SafeSFSymbols", "SmartCodable", "SmartCodable/Inherit", "SnapKit", "SwiftDate", "SwifterSwift", "lottie-ios"]
- `FaceIDPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `HealthPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]
- `LocationPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `MicPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `MotionPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `NetWork` / `internal_dependencies`: SPM=["Core", "Loading", "PToolsCore"]; CocoaPods=["Core", "Loading"]
- `NotificationPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `PagingControl` / `third_party_dependencies`: SPM=["JXPagingView", "JXSegmentedView"]; CocoaPods=["JXPagingView/Paging", "JXSegmentedView"]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "NetWork"]; CocoaPods=["Core", "ImagePicker", "Loading", "NetWork"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit", "SwifterSwift"]; CocoaPods=[]
- `RemindersPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `SiriPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `SpeechRecognizerPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `TrackingPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth"]; CocoaPods=[]

### Swift settings and macros

- `BluetoothPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH"], "upcoming_features"=>[]}
- `CalendarPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR"], "upcoming_features"=>[]}
- `CameraPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA"], "upcoming_features"=>[]}
- `ContactsPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS"], "upcoming_features"=>[]}
- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_CGDWEBSERVER", "POOTOOLS_COCOAPODS", "POOTOOLS_FLAG", "POOTOOLS_INSTRUCTIONS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_NOTIFICATIONBANNER", "POOTOOLS_PICKER", "POOTOOLS_POPOVERKIT", "POOTOOLS_SECURITYSUITE", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE", "POOTOOLS_ZIPARCHINE"], "upcoming_features"=>["InferSendableFromCaptures", "StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS"], "upcoming_features"=>[]}
- `FaceIDPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION"], "upcoming_features"=>[]}
- `HealthPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH"], "upcoming_features"=>[]}
- `LocationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION"], "upcoming_features"=>[]}
- `MeidaPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA"], "upcoming_features"=>[]}
- `MicPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION"], "upcoming_features"=>[]}
- `RemindersPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS"], "upcoming_features"=>[]}
- `SiriPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI"], "upcoming_features"=>[]}
- `SpeechRecognizerPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH"], "upcoming_features"=>[]}
- `TrackingPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
