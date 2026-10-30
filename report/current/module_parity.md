<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr46-pr50-inspector-layout-governance-20261030
Source revision: 98086745a5deb64f173282d5cdfa5faaed2e2106
Source version: 5.69.0
Source inputs digest: 8c745967288dcd0493111e7ec716d9f601938762a8f52bae2525c7d3591bb455
Generator version: 1
Generator: Scripts/validate_module_parity.sh
Generated at: 2026-10-30T03:49:02Z
-->

# SwiftPM / CocoaPods Module Parity

- Status: `baseline`
- Fingerprint: `4caec792bfe6308eebd9efd935abfce37c2db1ad6516fd8dfa165c0e9d8dd222`
- Matched modules: `123`
- SwiftPM-only modules: `48`
- CocoaPods-only modules: `38`
- Source-directory drift: `4`
- Dependency drift: `63`
- Swift setting / macro drift: `56`

## Classification

| Class | Modules / count |
| --- | --- |
| Matched | `Accessibility`, `Activities`, `AppIntents`, `Audio`, `BackgroundTasks`, `BankCard`, `Banner`, `BilogyID`, `Bluetooth`, `BluetoothPermission`, `Calendar`, `CalendarPermission`, `CameraPermission`, `CheckBox`, `CheckDirtyWord`, `CheckUpdate`, `ChinesePinyin`, `Circle`, `CodeView`, `Configuration`, `Connectivity`, `Contact`, `ContactsPermission`, `ContentState`, `Core`, `Country`, `CustomerLabel`, `CustomerNumberKeyboard`, `DEBUG`, `DEBUG_TrackingEyes`, `DataEncrypt`, `DeepLink`, `Device`, `Documents`, `FaceIDPermission`, `Feedback`, `Form`, `Guide`, `HTTPFilePortal`, `HTTPServer`, `HandSign`, `HarbethKit`, `HealthPermission`, `HeartRate`, `Hud`, `IAP`, `ImageEditor`, `ImagePicker`, `Input`, `Instructions`, `KeyChain`, `LaunchTimeProfiler`, `Layout`, `LivePhoto`, `Loading`, `Location`, `LocationPermission`, `Logging`, `MediaCore`, `MediaViewer`, `MeidaPermission`, `MessageKit`, `MicPermission`, `Model`, `ModelCore`, `Motion`, `MotionPermission`, `NetWork`, `NetworkSpeedTest`, `NotificationPermission`, `Notifications`, `OSSKitSpeech`, `Overlay`, `PDF`, `PToolsCore`, `PToolsModelCombine`, `PToolsModelUIKit`, `PToolsPermissionCore`, `PToolsPermissionUI`, `PToolsUIFoundation`, `PageControl`, `PagingControl`, `PhoneInfo`, `PhotoPicker`, `Picker`, `Ping`, `Popover`, `ProgressBar`, `RateView`, `RemindersPermission`, `RouteCore`, `Router`, `SVG`, `ScanQRCode`, `ScrollBanner`, `Search`, `SearchBar`, `Security`, `Segmented`, `Share`, `Simulation`, `SimulationCore`, `SiriPermission`, `Slider`, `SmartScreenshot`, `SocketKit`, `SpeechRecognizerPermission`, `SpeedPanel`, `SplitView`, `StepCount`, `Stepper`, `Storage`, `StorageCore`, `Symbols`, `Telephony`, `Theme`, `TipsView`, `TrackingPermission`, `VideoEditor`, `Vision`, `WhatsNewsKit`, `WidgetCore`, `iOS17Tips` |
| SwiftPM only | `PTAcknowledgementsGenerator`, `PTModelBenchmark`, `PTModelLegacyKakaJSONFixture`, `PTModelLegacySmartCodableFixture`, `PTModelMixedLegacyFixture`, `PTModelOnlyFixture`, `PToolsAcknowledgements`, `PToolsAcknowledgementsCore`, `PToolsAppIntegrity`, `PToolsAuth`, `PToolsAuthCore`, `PToolsConstraintLayout`, `PToolsDatabase`, `PToolsDatabaseCore`, `PToolsDate`, `PToolsDebugConsoleCore`, `PToolsDebugConsoleUI`, `PToolsDebugCore`, `PToolsDebugInspectorCore`, `PToolsDebugInspectorLegacyUI`, `PToolsDebugInspectorUI`, `PToolsDebugInventoryCore`, `PToolsDebugMetricsCore`, `PToolsDebugMetricsUI`, `PToolsDebugNetworkCore`, `PToolsDebugStorageCore`, `PToolsDebugStudioBridge`, `PToolsFontCatalogCore`, `PToolsMap`, `PToolsMapCore`, `PToolsModelLegacyKakaJSON`, `PToolsModelLegacySmartCodable`, `PToolsModelMacroPlugin`, `PToolsNetworkModelCore`, `PToolsObservability`, `PToolsObservabilityCore`, `PToolsRealtime`, `PToolsRealtimeCore`, `PToolsStoreKit`, `PToolsStudioProtocolCore`, `PToolsSync`, `PToolsSyncCore`, `PToolsTransfer`, `PToolsTransferCore`, `PToolsVariantCore`, `PToolsWeb`, `PToolsWebBridge`, `PToolsWebCore` |
| CocoaPods only | `Acknowledgements`, `AcknowledgementsCore`, `AppIntegrity`, `Appz`, `Auth`, `AuthCore`, `ConstraintLayout`, `DEBUG_StudioBridge`, `Database`, `DatabaseCore`, `Date`, `Flag`, `GCDWebServer`, `InputAll`, `MXMetricManagerKit`, `Map`, `MapCore`, `ModelLegacyKakaJSON`, `ModelLegacySmartCodable`, `NFCKit`, `NotificationBanner`, `Observability`, `ObservabilityCore`, `PopoverKit`, `Realtime`, `RealtimeCore`, `SecuritySuite`, `StoreKit`, `Sync`, `SyncCore`, `Tabbar`, `Transfer`, `TransferCore`, `VariantCore`, `Web`, `WebBridge`, `WebCore`, `ZipArchive` |

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

- `Core`: SPM=["ActionsheetAndAlert", "Animation", "AppDelegate", "AppStore", "ApplicationFunction", "Badge", "Base", "BlackMagic", "Blur", "Button", "Category", "Colors", "Core", "DarkMode", "FloatPanel", "Font/PTFont.swift", "Font/PTFontDescriptor.swift", "Font/PTFontRuntime.swift", "Foundation", "Language", "Line", "Log", "PermissionCore", "PhotoLibraryPermission", "Protocol", "Rotation", "SideMenuControl", "StatusBar", "Switch", "iCloud"]; CocoaPods=["ActionsheetAndAlert", "Animation", "AppDelegate", "AppStore", "ApplicationFunction", "Badge", "Base", "BlackMagic", "Blur", "Button", "Category", "Colors", "Core", "DarkMode", "FloatPanel", "Font", "Foundation", "Language", "Line", "Log", "PToolsFontCore", "PToolsPermissionCore", "PToolsTransferCore", "PermissionCore", "PhotoLibraryPermission", "Protocol", "Rotation", "SideMenuControl", "StatusBar", "Switch", "iCloud"]
- `DEBUG`: SPM=["DEBUGLocation", "Debug", "DebugCategory", "DebugColor", "DebugCrash", "DebugFile", "DebugLibs", "DebugNetwork", "DebugPerformance", "DebugRuler", "DebugUserDefault", "DevMask", "LocalConsole", "TouchInspector"]; CocoaPods=["DEBUGLocation", "Debug", "DebugCategory", "DebugColor", "DebugCrash", "DebugFile", "DebugLibs", "DebugNetwork", "DebugPerformance", "DebugRuler", "DebugUserDefault", "DevMask", "Inspector", "LocalConsole", "PToolsDebugConsoleUI", "PToolsDebugCore", "PToolsDebugInventoryCore", "PToolsDebugMetricsCore", "PToolsDebugMetricsUI", "TouchInspector"]
- `MeidaPermission`: SPM=["MeidaLibraryPermission"]; CocoaPods=[]
- `NetWork`: SPM=["NetWork"]; CocoaPods=["NetWork", "NetWorkModelCore"]

### Dependencies

- `Banner` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `CheckUpdate` / `internal_dependencies`: SPM=["Core", "Hud", "Loading", "NetWork"]; CocoaPods=["NetWork"]
- `CheckUpdate` / `third_party_dependencies`: SPM=["Swift-JWT"]; CocoaPods=["SwiftJWT"]
- `Configuration` / `internal_dependencies`: SPM=["Storage", "StorageCore"]; CocoaPods=["Storage"]
- `ContentState` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Core` / `internal_dependencies`: SPM=["Device", "Logging", "PToolsConstraintLayout", "PToolsCore", "PToolsDate", "PToolsFontCatalogCore", "PToolsPermissionCore", "PToolsTransferCore", "PToolsUIFoundation", "Symbols"]; CocoaPods=["Date", "Device", "Logging", "PToolsCore", "PToolsPermissionCore", "PToolsUIFoundation", "Symbols", "TransferCore"]
- `Core` / `third_party_dependencies`: SPM=["IQKeyboardManager", "Kingfisher", "SnapKit", "lottie-ios"]; CocoaPods=["IQKeyboardManagerSwift", "IQKeyboardToolbarManager", "Kingfisher", "SnapKit", "lottie-ios"]
- `CustomerLabel` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `CustomerNumberKeyboard` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `DEBUG` / `internal_dependencies`: SPM=["BackgroundTasks", "Connectivity", "Core", "DeepLink", "NetWork", "Notifications", "Overlay", "PDF", "PToolsDebugConsoleUI", "PToolsDebugCore", "PToolsDebugInspectorLegacyUI", "PToolsDebugInventoryCore", "PToolsDebugMetricsCore", "PToolsDebugMetricsUI", "PToolsDebugNetworkCore", "PToolsDebugStorageCore", "RouteCore", "SearchBar", "Share", "Storage", "Symbols"]; CocoaPods=["BackgroundTasks", "Connectivity", "Core", "DeepLink", "NetWork", "Notifications", "Overlay", "PDF", "RouteCore", "SearchBar", "Share", "Storage", "Symbols"]
- `DEBUG` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Documents` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Form` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Guide` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `HandSign` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `HarbethKit` / `internal_dependencies`: SPM=["CameraPermission", "Core", "Hud", "Loading", "MediaViewer", "Symbols"]; CocoaPods=["CameraPermission", "Core", "Symbols"]
- `HarbethKit` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=["Harbeth"]
- `HeartRate` / `third_party_dependencies`: SPM=["SnapKit", "lottie-ios"]; CocoaPods=["lottie-ios"]
- `Hud` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `ImageEditor` / `internal_dependencies`: SPM=["Core", "HarbethKit", "MediaCore", "PToolsCore", "PhotoPicker", "Symbols"]; CocoaPods=["Core", "HarbethKit", "MediaCore", "PhotoPicker", "Symbols"]
- `ImageEditor` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=[]
- `ImagePicker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Input` / `internal_dependencies`: SPM=["Core", "PToolsCore", "PToolsUIFoundation"]; CocoaPods=["Core", "PToolsUIFoundation"]
- `Instructions` / `internal_dependencies`: SPM=["Overlay"]; CocoaPods=["Core", "Overlay"]
- `Instructions` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `LaunchTimeProfiler` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Loading` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Location` / `internal_dependencies`: SPM=["Core", "LocationPermission", "Storage", "StorageCore"]; CocoaPods=["Core", "LocationPermission", "Storage"]
- `MediaViewer` / `internal_dependencies`: SPM=["Core", "LivePhoto", "MediaCore", "PToolsUIFoundation", "PageControl", "ProgressBar"]; CocoaPods=["Core", "LivePhoto", "MediaCore", "PageControl", "ProgressBar"]
- `MediaViewer` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `MeidaPermission` / `internal_dependencies`: SPM=["PToolsPermissionCore"]; CocoaPods=["MeidaPermission"]
- `MessageKit` / `internal_dependencies`: SPM=["Core", "CustomerLabel", "NetWork", "ProgressBar", "Symbols"]; CocoaPods=["Core", "CustomerLabel", "Symbols"]
- `MessageKit` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Model` / `internal_dependencies`: SPM=["ModelCore", "PToolsModelMacroPlugin"]; CocoaPods=["ModelCore"]
- `NetWork` / `internal_dependencies`: SPM=["Connectivity", "Core", "Loading", "ModelCore", "PToolsCore", "PToolsModelLegacyKakaJSON", "PToolsModelLegacySmartCodable", "PToolsNetworkModelCore", "PToolsTransferCore"]; CocoaPods=["Connectivity", "Core", "Loading", "ModelCore", "ModelLegacyKakaJSON", "ModelLegacySmartCodable", "TransferCore"]
- `PDF` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `PageControl` / `internal_dependencies`: SPM=["Core", "PToolsCore"]; CocoaPods=["Core"]
- `PagingControl` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `PhotoPicker` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "Loading", "MediaCore", "PToolsCore", "PToolsUIFoundation", "Symbols"]; CocoaPods=["Core", "ImagePicker", "Loading", "MediaCore", "Symbols"]
- `PhotoPicker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Picker` / `internal_dependencies`: SPM=["Core", "PToolsCore"]; CocoaPods=["Core"]
- `Picker` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Ping` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Popover` / `internal_dependencies`: SPM=["Overlay", "PToolsCore", "Symbols"]; CocoaPods=["Overlay", "Symbols"]
- `ProgressBar` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `RateView` / `internal_dependencies`: SPM=["Core"]; CocoaPods=["PToolsUIFoundation"]
- `SVG` / `third_party_dependencies`: SPM=["Kingfisher", "PocketSVG"]; CocoaPods=["PocketSVG", "Protobuf", "SVGAPlayer"]
- `ScanQRCode` / `internal_dependencies`: SPM=["CameraPermission", "Core", "ImagePicker", "PToolsCore", "PhotoPicker"]; CocoaPods=["CameraPermission", "Core", "PhotoPicker"]
- `ScanQRCode` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `ScrollBanner` / `internal_dependencies`: SPM=["Core", "PToolsUIFoundation", "PageControl"]; CocoaPods=["Core", "PageControl"]
- `ScrollBanner` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Search` / `internal_dependencies`: SPM=["Core", "PToolsCore", "PToolsUIFoundation", "SearchBar"]; CocoaPods=["Core", "PToolsUIFoundation", "SearchBar"]
- `Search` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Segmented` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `Slider` / `internal_dependencies`: SPM=[]; CocoaPods=["PToolsUIFoundation"]
- `Stepper` / `third_party_dependencies`: SPM=["SnapKit"]; CocoaPods=[]
- `TipsView` / `internal_dependencies`: SPM=["Core", "Overlay"]; CocoaPods=["Core"]
- `VideoEditor` / `internal_dependencies`: SPM=["Core", "HarbethKit", "Loading", "MediaCore", "PToolsCore", "ProgressBar", "Symbols"]; CocoaPods=["Core", "HarbethKit", "Loading", "MediaCore", "ProgressBar", "Symbols"]
- `VideoEditor` / `third_party_dependencies`: SPM=["Harbeth", "SnapKit"]; CocoaPods=[]
- `WhatsNewsKit` / `internal_dependencies`: SPM=["Core", "PToolsUIFoundation"]; CocoaPods=["Core"]
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
- `BluetoothPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_BLUETOOTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `CalendarPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_CALENDAR", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `CameraPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_CAMERA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Configuration`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_CONFIGURATION"], "upcoming_features"=>[]}
- `Connectivity`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_CONNECTIVITY"], "upcoming_features"=>[]}
- `ContactsPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_CONTACTS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `ContentState`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Core`: SPM={"defines"=>["POOTOOLS_APPZ", "POOTOOLS_COCOAPODS", "POOTOOLS_LAUNCHTIMEPROFILER", "POOTOOLS_PICKER", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION", "POOTOOLS_TABBAR", "POOTOOLS_VIDEOCACHE"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_EMBED_TRANSFER_CORE", "POOTOOLS_SPLIT_CORE", "POOTOOLS_SPLIT_PERMISSION_CORE", "POOTOOLS_SPLIT_UIFOUNDATION"], "upcoming_features"=>[]}
- `DeepLink`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_DEEPLINK"], "upcoming_features"=>[]}
- `Device`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Documents`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `FaceIDPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_FACEIDPERMISSION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Feedback`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_FEEDBACK"], "upcoming_features"=>[]}
- `Form`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HTTPFilePortal`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HTTPServer`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `HealthPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_HEALTH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Instructions`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_INSTRUCTIONS"], "upcoming_features"=>[]}
- `LocationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_LOCATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Logging`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_LOGGING"], "upcoming_features"=>[]}
- `MediaCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MeidaPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MEDIA", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `MicPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_MIC", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Model`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_MODEL"], "upcoming_features"=>[]}
- `ModelCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_MODEL_CORE"], "upcoming_features"=>[]}
- `MotionPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_MOTION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `NotificationPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_NOTIFICATION", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `Notifications`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_NOTIFICATIONS"], "upcoming_features"=>[]}
- `Overlay`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_OVERLAY"], "upcoming_features"=>[]}
- `PToolsCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsModelCombine`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsModelUIKit`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `PToolsPermissionCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE"], "upcoming_features"=>[]}
- `PToolsPermissionUI`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE"], "upcoming_features"=>[]}
- `PToolsUIFoundation`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Popover`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_POPOVER"], "upcoming_features"=>[]}
- `RemindersPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_REMINDERS", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `RouteCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_ROUTE_CORE"], "upcoming_features"=>[]}
- `Simulation`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `SimulationCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `SiriPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_SIRI", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `SpeechRecognizerPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_SPEECH", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `SplitView`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_SPLITVIEW"], "upcoming_features"=>[]}
- `Storage`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_STORAGE"], "upcoming_features"=>[]}
- `StorageCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_STORAGE_CORE"], "upcoming_features"=>[]}
- `Symbols`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `Theme`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>[], "upcoming_features"=>[]}
- `TrackingPermission`: SPM={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_EMBED_PERMISSION_CORE", "POOTOOLS_PERMISSION_TRACKING", "POOTOOLS_SPLIT_PERMISSION_CORE"], "upcoming_features"=>[]}
- `WidgetCore`: SPM={"defines"=>[], "upcoming_features"=>["StrictConcurrency"]}; CocoaPods={"defines"=>["POOTOOLS_COCOAPODS", "POOTOOLS_WIDGET_CORE"], "upcoming_features"=>[]}

## Gate behavior

- `--update` writes a reviewed baseline.
- `--check` (the default) compares the current stable fingerprint and fails on drift.
- This gate reports parity; it does not change either build entry or third-party dependencies.
