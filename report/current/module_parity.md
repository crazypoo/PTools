<!--
AUTO-GENERATED FILE.
DO NOT EDIT MANUALLY.

Generator: Scripts/validate_module_parity.sh
Source revision: 80126150505961e259cce5e08ada67962265c063
Generated at: 2026-10-18T05:02:35Z
-->

# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `013163fa4a9e0cbc7c6a1b868d64bd5a988d47a108631e4d97ef988ff56ea8b6`
- Matched modules: `123`
- SwiftPM-only modules: `34`
- CocoaPods-only modules: `36`
- Source-directory drift: `3`
- Dependency drift: `82`
- Swift setting / macro drift: `56`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `Accessibility`, `Activities`, `AppIntents`, `Audio`, `BackgroundTasks`, `BankCard`, `Banner`, `BilogyID`, `Bluetooth`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Configuration`, `Connectivity`, `Contact`, `ContactsPermission`, `ContentState`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `DeepLink`, `Device`, `Documents`, `FaceIDPermission`, `Feedback`, `Form`, `Guide`, `HTTPFilePortal`, `HTTPServer`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `Instructions`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `Logging`, `MediaCore`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Model`, `ModelCore`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `Notifications`, `OSSKitSpeech`, `Overlay`, `PDF`, `PToolsCore`, `PToolsModelCombine`, `PToolsModelUIKit`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `Popover`, `ProgressBar`, `RateView`, `RemindersPermission`, `RouteCore`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `Segmented`, `Share`, `Simulation`, `SimulationCore`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `SplitView`, `StepCount`, `Stepper`, `Storage`, `StorageCore`, `Symbols`, `Telephony`, `Theme`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `WidgetCore`, `iOS17Tips` |
| SwiftPM only | `PTAcknowledgementsGenerator`, `PTModelBenchmark`, `PTModelLegacyKakaJSONFixture`, `PTModelLegacySmartCodableFixture`, `PTModelMixedLegacyFixture`, `PTModelOnlyFixture`, `PToolsAcknowledgements`, `PToolsAcknowledgementsCore`, `PToolsAppIntegrity`, `PToolsAuth`, `PToolsAuthCore`, `PToolsConstraintLayout`, `PToolsDatabase`, `PToolsDatabaseCore`, `PToolsDate`, `PToolsFontCatalogCore`, `PToolsMap`, `PToolsMapCore`, `PToolsModelLegacyKakaJSON`, `PToolsModelLegacySmartCodable`, `PToolsModelMacroPlugin`, `PToolsNetworkModelCore`, `PToolsObservability`, `PToolsObservabilityCore`, `PToolsRealtime`, `PToolsRealtimeCore`, `PToolsStoreKit`, `PToolsSync`, `PToolsSyncCore`, `PToolsTransfer`, `PToolsTransferCore`, `PToolsWeb`, `PToolsWebBridge`, `PToolsWebCore` |
| CocoaPods only | `Acknowledgements`, `AcknowledgementsCore`, `AppIntegrity`, `Appz`, `Auth`, `AuthCore`, `ConstraintLayout`, `Database`, `DatabaseCore`, `Date`, `Flag`, `GCDWebServer`, `InputAll`, `MXMetricManagerKit`, `Map`, `MapCore`, `ModelLegacyKakaJSON`, `ModelLegacySmartCodable`, `NFCKit`, `NotificationBanner`, `Observability`, `ObservabilityCore`, `PopoverKit`, `Realtime`, `RealtimeCore`, `SecuritySuite`, `StoreKit`, `Sync`, `SyncCore`, `Tabbar`, `Transfer`, `TransferCore`, `Web`, `WebBridge`, `WebCore`, `ZipArchive` |

## Compatibility products

These entries are explicit product mappings, not parity exceptions or duplicated source implementations.

| Module | SwiftPM product | SwiftPM target | CocoaPods subspec | Source ownership |
| --- | --- | --- | --- | --- |
| `WebKit` | `PooToolsWebKit` | `PooToolsWebKit` | `WebKit` | `PooToolsSource/WebKit` |
| `VideoCache` | `PooToolsVideoCache` | `ptools` | `VideoCache` | `PooToolsSource/Base` |
| `FilterCamera` | `PooToolsFilterCamera` | `PooToolsFilterCamera` | `FilterCamera` | `PooToolsSource/C7Collector` |

## Drift details

The baseline records existing differences as explicit review items. A later manifest or podspec change must update this baseline only after review.

### Source directories

- `Core`: SPM=["ActionsheetAndAlert", "Animation", "AppDelegate", "AppStore", "ApplicationFunction", "Badge", "Base", "BlackMagic", "Blur", "Button", "Category", "Colors", "Core", "DarkMode", "FloatPanel", "Font/PTFont.swift", "Font/PTFontDescriptor.swift", "Font/PTFontRuntime.swift", "Foundation", "Language", "Line", "Log", "PermissionCore", "PhotoLibraryPermission", "Protocol", "Rotation", "SideMenuControl", "StatusBar", "Switch", "iCloud"]; CocoaPods=["ActionsheetAndAlert", "Animation", "AppDelegate", "AppStore", "ApplicationFunction", "Badge", "Base", "BlackMagic", "Blur", "Button", "Category", "Colors", "Core", "DarkMode", "FloatPanel", "Font", "Foundation", "Language", "Line", "Log", "PToolsFontCore", "PermissionCore", "PhotoLibraryPermission", "Protocol", "Rotation", "SideMenuControl", "StatusBar", "Switch", "iCloud"]
- `MeidaPermission`: SPM=["MeidaLibraryPermission"]; CocoaPods=[]
- `NetWork`: SPM=["NetWork"]; CocoaPods=["NetWork", "NetWorkModelCore"]

### Dependencies

- `Banner` / `internal_dependencies`: SPM=["Logging", "Overlay", "PToolsConstraintLayout", "PToolsCore", "Symbols"]; CocoaPods=["ConstraintLayout", "Logging", "Overlay", "PToolsCore", "Symbols"]
- `Banner` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `BluetoothPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `CheckUpdate` / `internal_dependencies`: SPM=["Core", "Hud", "Loading", "NetWork", "PToolsConstraintLayout"]; CocoaPods=["NetWork"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `Configuration` / `internal_dependencies`: SPM=["Storage", "StorageCore"]; CocoaPods=["Storage"]
- `ContentState` / `internal_dependencies`: SPM=["Accessibility", "Connectivity", "Core", "PToolsConstraintLayout", "Theme"]; CocoaPods=["Accessibility", "Connectivity", "Core", "Theme"]
- `ContentState` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Core` / `internal_dependencies`: SPM=["Device", "Logging", "PToolsConstraintLayout", "PToolsCore", "PToolsDate", "PToolsFontCatalogCore", "PToolsPermissionCore", "PToolsUIFoundation", "Symbols"]; CocoaPods=["ConstraintLayout", "Date", "Device", "Logging", "PToolsCore", "PToolsUIFoundation", "Symbols"]
- `Core` / `third_party_dependencies`: SPM=["IQKeyboardManager", "Kingfisher", "SnapKit", "lottie-ios"]; CocoaPods=["IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "Kingfisher", "SnapKit", "lottie-ios"]
- `CustomerLabel` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `CustomerLabel` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `CustomerNumberKeyboard` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `DEBUG` / `internal_dependencies`: SPM=["BackgroundTasks", "Connectivity", "Core", "DeepLink", "NetWork", "Notifications", "Overlay", "PDF", "PToolsConstraintLayout", "RouteCore", "SearchBar", "Share", "Storage", "Symbols"]; CocoaPods=["BackgroundTasks", "Connectivity", "Core", "DeepLink", "NetWork", "Notifications", "Overlay", "PDF", "RouteCore", "SearchBar", "Share", "Storage", "Symbols"]
- `DEBUG` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Documents` / `internal_dependencies`: SPM=["PDF", "PToolsConstraintLayout"]; CocoaPods=["PDF"]
- `Documents` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Form` / `internal_dependencies`: SPM=["Accessibility", "CheckBox", "ContentState", "Core", "Input", "PToolsConstraintLayout", "PToolsCore", "Picker", "Slider", "Stepper", "Theme"]; CocoaPods=["Accessibility", "CheckBox", "ContentState", "Core", "Input", "PToolsCore", "Picker", "Slider", "Stepper", "Theme"]
- `Form` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Guide` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PageControl"]; CocoaPods=["Core", "PageControl"]
- `Guide` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `HandSign` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `HandSign` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `HarbethKit` / `internal_dependencies`: SPM=["CameraPermission", "Core", "Hud", "Loading", "MediaViewer", "PToolsConstraintLayout", "Symbols"]; CocoaPods=["CameraPermission", "Core", "Symbols"]
- `HarbethKit` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=["Harbeth"]
- `HeartRate` / `internal_dependencies`: SPM=["CameraPermission", "Core", "PToolsConstraintLayout"]; CocoaPods=["CameraPermission", "Core"]
- `HeartRate` / `third_party_dependencies`: SPM=["SnapKit", "lottie-ios"]; CocoaPods=["lottie-ios"]
- `Hud` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "ProgressBar"]; CocoaPods=["Core", "ProgressBar"]
- `Hud` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `ImageEditor` / `internal_dependencies`: SPM=["Core", "HarbethKit", "MediaCore", "PToolsConstraintLayout", "PToolsCore", "PhotoPicker", "Symbols"]; CocoaPods=["Core", "HarbethKit", "MediaCore", "PhotoPicker", "Symbols"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=[]
- `ImagePicker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Input` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PToolsCore", "PToolsUIFoundation"]; CocoaPods=["Core", "PToolsUIFoundation"]
- `Instructions` / `internal_dependencies`: SPM=["Overlay", "PToolsConstraintLayout"]; CocoaPods=["Core", "Overlay"]
- `Instructions` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `LaunchTimeProfiler` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `LaunchTimeProfiler` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Loading` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `Loading` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Location` / `internal_dependencies`: SPM=["Core", "LocationPermission", "Storage", "StorageCore"]; CocoaPods=["Core", "LocationPermission", "Storage"]
- `MediaViewer` / `internal_dependencies`: SPM=["Core", "LivePhoto", "MediaCore", "PToolsConstraintLayout", "PToolsUIFoundation", "PageControl", "ProgressBar"]; CocoaPods=["Core", "LivePhoto", "MediaCore", "PageControl", "ProgressBar"]
- `MediaViewer` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["MeidaPermission"]
- `MessageKit` / `internal_dependencies`: SPM=["Core", "CustomerLabel", "NetWork", "PToolsConstraintLayout", "ProgressBar", "Symbols"]; CocoaPods=["Core", "CustomerLabel", "Symbols"]
- `MessageKit` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Model` / `internal_dependencies`: SPM=["ModelCore", "PToolsModelMacroPlugin"]; CocoaPods=["ModelCore"]
- `NetWork` / `internal_dependencies`: SPM=["Connectivity", "Core", "Loading", "ModelCore", "PToolsCore", "PToolsModelLegacyKakaJSON", "PToolsModelLegacySmartCodable", "PToolsNetworkModelCore"]; CocoaPods=["Connectivity", "Core", "Loading", "ModelCore", "ModelLegacyKakaJSON", "ModelLegacySmartCodable"]
- `PDF` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `PDF` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `PageControl` / `internal_dependencies`: SPM=["Core", "PToolsCore"]; CocoaPods=["Core"]
- `PagingControl` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `PagingControl` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "MediaCore", "PToolsConstraintLayout", "PToolsUIFoundation", "Symbols"]; CocoaPods=["Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]
- `PhotoPicker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Picker` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PToolsCore"]; CocoaPods=["Core"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Ping` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `Ping` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Popover` / `internal_dependencies`: SPM=["Overlay", "PToolsCore", "Symbols"]; CocoaPods=["Overlay", "Symbols"]
- `ProgressBar` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `ProgressBar` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `RateView` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["ConstraintLayout", "PToolsUIFoundation"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PToolsConstraintLayout", "PToolsCore", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `ScanQRCode` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `ScrollBanner` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PToolsUIFoundation", "PageControl"]; CocoaPods=["Core", "PageControl"]
- `ScrollBanner` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Search` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PToolsUIFoundation", "SearchBar"]; CocoaPods=["Core", "PToolsUIFoundation", "SearchBar"]
- `Search` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Segmented` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Share` / `internal_dependencies`: SPM=["Core", "CustomerLabel", "PToolsConstraintLayout"]; CocoaPods=["Core", "CustomerLabel"]
- `SiriPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["Core"]
- `Slider` / `internal_dependencies`: SPM=["PToolsConstraintLayout"]; CocoaPods=["ConstraintLayout", "PToolsUIFoundation"]
- `Stepper` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout"]; CocoaPods=["Core"]
- `Stepper` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `TipsView` / `internal_dependencies`: SPM=["Core", "Overlay"]; CocoaPods=["Core"]
- `VideoEditor` / `internal_dependencies`: SPM=["Core", "HarbethKit", "Loading", "MediaCore", "PToolsConstraintLayout", "PToolsCore", "ProgressBar", "Symbols"]; CocoaPods=["Core", "HarbethKit", "Loading", "MediaCore", "ProgressBar", "Symbols"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=[]
- `WhatsNewsKit` / `internal_dependencies`: SPM=["Core", "PToolsConstraintLayout", "PToolsUIFoundation"]; CocoaPods=["Core"]
- `WhatsNewsKit` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `WidgetCore` / `internal_dependencies`: SPM=["DeepLink", "RouteCore", "Storage", "StorageCore"]; CocoaPods=["DeepLink", "RouteCore", "Storage"]
- `iOS17Tips` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]

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
- `Model`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_MODEL"], "upcoming_features"=>[]}
- `ModelCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_MODEL_CORE"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION"], "upcoming_features"=>[]}
- `Notifications`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_NOTIFICATIONS"], "upcoming_features"=>[]}
- `Overlay`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>[]}
- `PToolsCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsModelCombine`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsModelUIKit`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
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
- `SplitView`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_SPLITVIEW"], "upcoming_features"=>[]}
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
