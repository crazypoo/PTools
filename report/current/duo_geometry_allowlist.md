# iPhone Duo geometry allowlist / Lista de excepciones / 几何白名单

Source revision: 6659aef825fba5ebaba376922681f56f7df62918
Audit rule version: 5.69.0-duo-2026-10-24-r4

Only the listed path and kinds are waived. Any new path remains `needs-review`.
Solo se eximen la ruta y los tipos listados. Una ruta nueva queda en `needs-review`.
仅豁免下列路径和类型；新增路径始终进入 `needs-review`。

| Path | Kinds | Reviewer | Reason |
| --- | --- | --- | --- |
| `PooToolsSource/C7Collector/PTFilterCameraViewController.swift` | `kSCREEN` | PTools Duo audit | Camera image-processing output size. |
| `PooToolsSource/C7Collector/PTHarBethFilter.swift` | `kSCREEN` | PTools Duo audit | Render texture default; caller can provide a local texture size. |
| `PooToolsSource/Category/CGFloat+PTEX.swift` | `UIScreen.main, kSCREEN, safe-area-global` | PTools Duo audit | Legacy scalar APIs and display-scale compatibility. |
| `PooToolsSource/Category/UICollectionView+PTEX.swift` | `kSCREEN` | PTools Duo audit | Legacy default width when no owner view is supplied. |
| `PooToolsSource/Category/UIImage+PTEX.swift` | `UIScreen.main` | PTools Duo audit | Pixel-domain image processing, not UIKit placement. |
| `PooToolsSource/Category/UIScreen+PTEX.swift` | `UIScreen.main, UIScreen.size` | PTools Duo audit | Display metadata only; window-local size API is available. |
| `PooToolsSource/Core/PTMarcos_swift.swift` | `all` | PTools Duo audit | Public compatibility snapshots; not a layout source. |
| `PooToolsSource/DarkMode/PTDarkFollowSystemFooter.swift` | `kSCREEN` | PTools Duo audit | Static legacy text layout default; runtime containers override it. |
| `PooToolsSource/DarkMode/PTDarkSmartFooter.swift` | `kSCREEN` | PTools Duo audit | Static legacy text layout default; runtime containers override it. |
| `PooToolsSource/DebugColor/PTColorPickPlugin.swift` | `kSCREEN` | PTools Duo audit | Pixel color conversion scale. |
| `PooToolsSource/DebugCrash/PTCrashDetailViewController.swift` | `kSCREEN` | PTools Duo audit | Legacy text measurement fallback. |
| `PooToolsSource/DebugCrash/PTCrashLogViewController.swift` | `kSCREEN` | PTools Duo audit | Legacy text measurement fallback. |
| `PooToolsSource/DebugFile/PTFileBrowserViewController.swift` | `kSCREEN` | PTools Duo audit | Popover fallback frame; current window is preferred when available. |
| `PooToolsSource/DebugLibs/PTLoadedLibsViewController.swift` | `kSCREEN` | PTools Duo audit | Legacy debug title sizing fallback. |
| `PooToolsSource/DebugPerformance/PTDebugPerformanceToolKit.swift` | `kSCREEN, statusBarHeight` | PTools Duo audit | Debug floating control fallback. |
| `PooToolsSource/DebugPerformance/PTDebugPerformanceViewController.swift` | `kSCREEN` | PTools Duo audit | Debug-only layout fallback. |
| `PooToolsSource/DebugRuler/PTViewRulerPlugin.swift` | `kSCREEN` | PTools Duo audit | Debug overlay fallback before host layout. |
| `PooToolsSource/Loading/PTHudView.swift` | `kSCREEN` | PTools Duo audit | Legacy maximum configuration bound. |
| `PooToolsSource/LocalConsole/LocalConsole.swift` | `UIScreen.main` | PTools Duo audit | Debug display diagnostics only; never used for feature layout. |
| `PooToolsSource/PermissionCore/PTPermissionHeader.swift` | `kSCREEN` | PTools Duo audit | Legacy compatibility API; new callers pass container width. |
| `PooToolsSource/PermissionCore/PTPermissionViewController.swift` | `kSCREEN` | PTools Duo audit | Legacy compatibility path retained outside local header measurement. |
| `PooToolsSource/Protocol/PTProtocol.swift` | `kSCREEN` | PTools Duo audit | Legacy device scaling policy. |
| `PooToolsSource/Stepper/PTStepperView.swift` | `kSCREEN` | PTools Duo audit | Legacy content width fallback when no local width exists. |
