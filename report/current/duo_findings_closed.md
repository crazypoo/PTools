<!-- AUTO-GENERATED: Scripts/audit_duo_uikit_coverage.py -->
Source revision: 6659aef825fba5ebaba376922681f56f7df62918
Generated at: 2026-10-24T06:06:15.807222+00:00
Audit rule version: 5.69.0-duo-2026-10-24-r4
Source manifest hash: 5695ad4f624d2d0006687d66bec5602618663f6c28d0b18315f5d4e75ae259bc

# iPhone Duo Findings Closure / Hallazgos / 审计项闭环

| ID | 文件 | 决定 | 静态状态 | 运行/设备状态 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `DUO-A01` | `PooToolsSource/Core/PTMarcos_swift.swift` | `display-only-allowed` | `pass_static` | `pending_device` | 历史兼容全局值，仅允许展示、像素或兼容读取 |
| `DUO-A02` | `PooToolsSource/Category/AutoScale+PTEX.swift` | `fixed` | `pass_static` | `pending_device` | 新版缩放支持 View-local overload，旧入口保留兼容 |
| `DUO-A03` | `PooToolsSource/Inspector/ElementInspectorConfiguration.swift` | `fixed` | `pass_static` | `pending_device` | 面板宽度从宿主 bounds 解析 |
| `DUO-A04` | `PooToolsSource/WhereIsMyEye/PTEyeTrackingDataManager.swift` | `fixed` | `pass_static` | `pending_device` | 物理标定与 View 坐标映射分离，并对不可信状态降级 |
| `DUO-A05` | `PooToolsSource/Category/UIScreen+PTEX.swift` | `display-only-allowed` | `pass_static` | `pending_device` | UIScreen.size 仅作为显示器元数据 |
| `DUO-A06` | `PooToolsSource/Category/CGFloat+PTEX.swift` | `fixed` | `pass_static` | `pending_device` | 旧安全区符号保留兼容，新布局提供局部 View 入口 |
| `DUO-N01` | `PooToolsSource/Category/UIImageView+PTEX.swift` | `fixed` | `pass_static` | `pending_device` | 同一 Window 坐标系和可视 pane 判断 |
| `DUO-N02` | `PooToolsSource/PhotoPicker/PTMediaLibViewController.swift` | `fixed` | `pass_static` | `pending_device` | fakeNav 使用真实 pullbar frame、本地 safe area 和幂等 inset 更新 |
| `DUO-N03` | `PooToolsSource/Base/PTBaseWebViewController.swift` | `fixed` | `pass_static` | `pending_device` | WebView top constraint 使用实测局部导航边界 |
| `DUO-N04` | `PooToolsSource/MediaViewer/PTMediaBrowserCell.swift` | `fixed` | `pass_static` | `pending_device` | 零尺寸时延后解码而不是读取主屏 |
| `DUO-N05` | `PooToolsSource/LocalConsole/LocalConsole.swift` | `fixed` | `pass_static` | `pending_device` | 控制台方向和起始位置使用宿主 bounds |
| `DUO-N06` | `PooToolsSource/Inspector/ViewHierarchyRoot.swift` | `fixed` | `pass_static` | `pending_device` | Inspector 根节点跟随被检查 Window |
| `DUO-N07` | `PooToolsSource/QRCodeScan/PTScanQRController.swift` | `fixed` | `pass_static` | `pending_device` | 扫码控件使用宿主 safe area |
| `DUO-N08` | `PooToolsSource/DebugNetwork/PTNetworkWatcherViewController.swift` | `fixed` | `pass_static` | `pending_device` | Debug overlay 使用当前控制器宿主 |
| `DUO-N09` | `PooToolsSource/Category/UIImage+PTEX.swift` | `fixed` | `pass_static` | `pending_device` | 像素化尺度脱离主屏幕宽度 |
