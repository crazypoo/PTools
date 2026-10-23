# PTools iPhone Duo 自适应 Navigation / TabBar

## 目标

PTools 5.63.0 为 `PTBaseNavControl`、`PTBaseTabBarViewController` 和 `PTTabBarView` 增加了统一的自适应 Bar 几何入口，面向 iOS 17+ / Swift 6+。实现不通过机型名称、屏幕固定宽高或 `UIScreen.main` 判断 Duo，而是读取当前 Scene 宿主 View 的 bounds、四边 safe area、iOS 27.1+ 的 `verticalBarEdge` 和 active reserved regions。

English: Adaptive bars use the current scene geometry and UIKit capabilities instead of device-name checks.

Español: Las barras adaptativas usan la geometría de la escena actual y las capacidades de UIKit, no el nombre del dispositivo.

## 默认用法

现有基类和公开入口无需修改。需要显式配置时，在 TabBar Controller 的初始化阶段设置实例级策略：

```swift
@MainActor
final class MyTabBarController: PTBaseTabBarViewController {
    override func viewDidLoad() {
        adaptiveBarPresentationPolicy = .automatic
        super.viewDidLoad()
        configure(items: makeItems())
        ptCustomBar.setup(configs: makeItems())
    }
}
```

策略含义：

- `.automatic`：iOS 17～27.0 或系统没有提供 vertical edge 时保持既有横向自定义 Bar；iOS 27.1+ 系统具备垂直 Bar 时优先让 UIKit 统一拥有导航和 Tab 的几何。
- `.preferSystemAdaptive`：明确优先 UIKit 系统承载，适合标准 `UIBarButtonItem`、`UITabBarItem` 内容。
- `.customAdaptive`：保留 PTools 自定义 Tab rail；不支持被压缩到垂直 rail 的自定义导航 View 时，导航栏保持经典模式，避免两套交互区域重叠。
- `.preferClassicBarsForWideContent`：明确的经典布局 opt-out，只用于业务已经验证的宽内容场景。
- `.legacyClassic`：回退到原有横向实现。

`PTAppBaseConfig.share.adaptiveBarPresentationPolicy` 只作为新控制器的默认值；不要在多个 Scene 运行中修改它来共享状态。已有 `tabItemContentInsets`、`tabSelectedMetailInsets`、`tabItemContentOffset` 的语义不变。

## 通用可视区域与业务控件

`PTAdaptiveVisibleRegionResolver` 是浮层、索引、分页和内容控件共用的轻量适配器。它只读取当前宿主 View 的 `bounds`、`safeAreaInsets`、`reservedRegions` 和布局方向，不创建全局单例，也不按设备名称分支：

```swift
let region = PTAdaptiveVisibleRegionResolver.region(for: hostView, minimumMargin: 4)
let frame = PTAdaptiveVisibleRegionResolver.controlFrame(
    size: CGSize(width: 80, height: 44),
    in: region,
    preferred: .trailing
)
```

`visibleRect` 是兼容旧入口的最大可用面板；`availablePanes` 是当前所有不与 active reserved region 相交的可用面板。双栏、Grid、SplitView 等内容应优先遍历 `availablePanes`，普通单控件可以继续使用 `visibleRect`。如果没有任何候选位置能够容纳交互控件，`controlFrame` 返回 `.zero`，调用方应转入 overflow、滚动或其他面板，不得把控件强行放回遮挡区。

English: `visibleRect` preserves the legacy largest-pane contract; `availablePanes` exposes every non-occluded pane for grids and split content.

Español: `visibleRect` conserva el contrato heredado del panel mayor; `availablePanes` expone todos los paneles sin oclusión para grids y contenido dividido.

背景媒体可以继续铺满宿主；Skip、Done、Badge、Index bubble、分享卡片、聊天气泡和分页 Segment 等交互内容应使用该适配器或同一 `contentSafeRect`。当当前形态存在 active occlusion / division 时，控件必须留在可视区域内，触摸尺寸保持至少 44 pt。旧 API 的绝对坐标语义继续保留；Badge 新代码可使用 `PTBadgeConfiguration.anchor` 与 `offset`。

English: Keep immersive backgrounds full bleed, but resolve interactive controls from the host-local visible region.

Español: Mantén los fondos inmersivos a pantalla completa, pero resuelve los controles interactivos desde la región visible local del host.

中文：沉浸式背景可以全幅显示，但交互控件必须基于宿主局部可视区域定位。

## 自定义导航页

`PTBaseViewController` 仍可覆写 `pt_Title`、`preferredNavigationBarStyle()`、`prefersLargeTitle()` 等旧 API。非基类控制器可以实现 `PTAdaptiveNavigationMetadataProviding`，只提供标题或轴偏好，不必改变旧的 `PTNavigationConfigurable`。

导航和 TabBar 的状态不会因尺寸变化而重建：当前 selected index、导航栈、Badge、Lottie 内容、输入文本和 accessory 状态由原控制器继续持有。系统模式下，PTools 会为 `PTTabBarItemConfig` 写入语义标题，并在缺少系统图标时使用安全的 `circle` fallback；原有自定义内容仍由旧 renderer 使用。

## 几何和安全区规则

- 所有布局取当前宿主 View 的 bounds 和 `safeAreaInsets`，四边分别处理。
- iOS 27.1+ 只在 UIKit 给出 `.leading` / `.trailing` 时启用垂直轴；`unspecified` 不被猜成某一侧。
- `occlusion` 和 `division` 的 active reserved regions 会进入几何快照，rail 不放置在禁区内。
- 重要操作的最小触摸目标为 44 pt；空间不足时优先保留返回/关闭、主要操作和当前选中 Tab，其余进入 overflow。
- 不使用 `UIScreen.main`、设备型号、`UIDevice.isFaceIDCapable` 或固定屏幕尺寸推断 Duo。
- Geometry signatures include local bounds, four safe-area insets, layout direction, vertical edge and reserved rectangles; resize invalidation is therefore local and repeatable.
- Las firmas geométricas incluyen límites locales, los cuatro insets seguros, dirección, borde vertical y rectángulos reservados; la invalidación tras redimensionar es local y repetible.
- 几何签名包含局部 bounds、四边安全区、布局方向、垂直边缘和保留区域矩形，尺寸变化后的失效处理可重复且不会复用旧场景状态。

## Debug 观察

开发期可以打开：

```swift
showsAdaptiveBarDebugOverlay = true
```

`adaptiveBarGeometry` 提供当前值类型快照，包括 `axis`、`renderer`、`edge`、`contentSafeRect`、`navItemsRect`、`tabItemsRect`、`accessoryRect`、可见 Tab 和 overflow Tab。DEBUG overlay 会绘制内容、导航、Tab、accessory 和 reserved region 矩形，并输出坐标摘要；Release 不绘制这些诊断内容。

## Demo 入口

Example 的 `Navigation & Routing` 分类新增 `iPhone Duo Adaptive Bars`，并在普通 Demo Catalog 中登记 18 个专项入口：

- `Duo · PhotoPicker Adaptive Grid`
- `Duo · ImageEditor Safe Controls`
- `Duo · VideoEditor Timeline Safe Controls`
- `Duo · MediaViewer Paging Integrity`
- `Duo · MediaViewer Bottom Controls`
- `Duo · MessageKit Safe Chat`
- `Duo · LargeTitle Nav Ownership`
- `Duo · Tab Accessory Search`
- `Duo · Paging + Segmented + Nested Scroll`
- `Duo · Unified Region Collision Stress`
- `Duo · Alert / ActionSheet`
- `Duo · Overlay / Popover / Banner`
- `Duo · Form / Keyboard / Search`
- `Duo · Collection All Layouts`
- `Duo · Split Page Container`
- `Duo · Picker / Permission / System`
- `Duo · Debug Overlay / Guide`
- `Duo · RTL / Dynamic Type`

这些入口复用现有 PhotoPicker、ImageEditor、VideoEditor、MediaViewer、MessageKit、TabBar 和 Paging Demo，不额外复制业务控制器。

`iPhone Duo Adaptive Bars` 覆盖：

1. Outer / Vertical Nav + Tabs
2. Inner Portrait / Classic
3. Inner Landscape / Auto Edge
4. Expanded / Prefer Classic
5. Center Raised + Lottie
6. Badge + Selection + Mini
7. Push / Pop / Interactive Pop
8. Search + Keyboard + Overflow
9. Accessibility
10. Multi Scene / Split View
11. FakeNav / Modal / Sheet / Alert
12. Rapid Fold / Resize Stress

新增入口的最小验证范围：

1. Alert / ActionSheet：多按钮、长文本、Dynamic Type、键盘和取消按钮可达。
2. Overlay / Popover / Banner：四边 anchor、Scene 切换、折叠保留区和 dismiss 命中区域。
3. Form / Keyboard / Search：错误 footer、取消按钮、数字键盘和输入焦点保留。
4. Collection All Layouts：Normal、Grid、Waterfall、Tag、Horizontal、Custom 的运行时切换。
5. Split Page Container：展开／折叠、选中页面和嵌套滚动状态保留。
6. Picker / Permission / System：系统权限、相册、相机和 Document/Picker presentation。
7. Debug Overlay / Guide：Console、Inspector、Guide spotlight 和 LaunchAd skip 绑定当前 Scene。
8. RTL / Dynamic Type：阿拉伯语、超大字体、VoiceOver 和 Reduce Motion。

每个入口都必须在外屏闭合、内屏两种方向、部分折叠、窗口尺寸变化、多 Scene、键盘和动画转场下复核；未具备对应设备条件时必须记录为“未测”，不能用几何单测代替真机结论。

## 全库审计与验收记录

`Scripts/audit_duo_uikit_coverage.py` 会扫描受版本控制的 UIKit/SwiftUI/测试源码，生成：

- `report/current/duo_uikit_inventory.csv`：文件、模块、公开 API、风险、布局方式、Demo／测试映射。
- `report/current/duo_global_geometry_hits.json`：全局几何候选的文件、行号和原始上下文。
- `report/current/duo_coverage.md`：模块级覆盖状态；`needs-review` 代表需要语义复核，不代表已经确认 Bug。

真实 Duo 的姿态、折叠保留区、系统侧栏、键盘和多 Scene 结果记录在 `report/current/duo_device_acceptance.md`。静态扫描、Xcode 编译和几何单测只能证明对应层级，不能代替设备视觉与交互验收。

### 报告快照与几何白名单

审计报告分为两类：CI 在当前 checkout 即时生成的报告，以及仓库内保存的不可变快照。CI 使用：

```bash
python3 Scripts/audit_duo_uikit_coverage.py . --strict
python3 Scripts/audit_duo_uikit_coverage.py . --check --strict
```

已提交快照不能自引用未来 Git commit；需要检查它时使用：

```bash
python3 Scripts/audit_duo_uikit_coverage.py . --check-committed-snapshot
```

该命令在 revision 或 manifest 不一致时只报告 `STALE SNAPSHOT`，不会把快照冒充当前 checkout 的通过证据。`duo_test_matrix_template.md` 是扫描器生成的初始模板，`duo_test_matrix.md` 是保留人工运行、视觉和设备证据的结果文件，扫描器不会把已有证据重置为 `pending`。`duo_geometry_allowlist.md` 逐条记录历史兼容、像素域、诊断和显示器元数据命中；新的命中默认进入 `needs-review`，不会因为所属模块有 Demo 或 XCTest 就自动通过。

English: CI reports are generated and checked on the same checkout. Committed snapshots are immutable references and stale snapshots warn instead of claiming a current pass.

Español: Los informes de CI se generan y comprueban en el mismo checkout. Las instantáneas committeadas son referencias inmutables; una instantánea obsoleta avisa y no se presenta como aprobación actual.

## 验证边界

几何单测使用可注入的 bounds、safe area、edge 和 reserved region，不要求实体设备；同时覆盖可视区域避让、多个可用 pane 和 hinge division。脚本 `Scripts/validate_duo_adaptive_bars.sh` 会先生成全库审计报告，再检查共享 Bar、媒体、分享、MessageKit、Paging 操作层不得新增全局屏幕尺寸定位，并校验 18 个 Demo 登记。完整 Xcode Simulator Debug / Release 构建用于验证 iOS 17+ 编译、旧横向回归和 Example 入口。

真实 iPhone Duo 的外屏、内屏、折叠转场、相机遮挡区、Live Activity、PiP、分屏和硬件触控仍需要在 Apple 提供的 Duo Simulator / Device Hub 或实体设备上验收；普通 iPhone 模拟器不能证明真实折叠行为。

## 2026-10-23 增量审计与证据边界

本轮 5.69.0 增量审计复用了现有的 `PTAdaptiveBarLayoutContext`、`PTAdaptiveVisibleRegionResolver` 和 `PTSceneContext`，没有新增并行几何体系。`Scripts/audit_duo_uikit_coverage.py --strict` 现在会记录每个命中文件的 owner、目标、行号、布局语义、处理决定、测试归属、运行状态和 reviewer，并把源文件清单、规则版本及 SHA-256 写入报告；过期报告会被判定为 `STALE`。

本轮已收口的高风险入口包括：同一 Window 坐标系下的图片可见性、PhotoPicker fake navigation bar、WebView 导航顶部约束、MediaViewer 零尺寸首屏解码、Inspector 面板尺寸、QRCode/DebugNetwork 控件安全区、LocalConsole 宿主窗口和图片像素化尺度。保留的全局兼容常量和 `UIScreen.size` 仅允许作为展示/物理元数据读取，新的布局代码必须使用宿主 View、Window 或 Scene 的局部几何。

English: The 2026-10-23 audit reuses the existing adaptive geometry owners. Reports are source-revision and manifest-bound; static/build evidence is separate from Duo-only visual and interaction evidence.

Español: La auditoría del 23-10-2026 reutiliza los propietarios geométricos adaptativos existentes. Los informes quedan ligados a la revisión y al manifiesto; la evidencia estática/de compilación se separa de la validación visual e interactiva exclusiva de Duo.

本轮 Xcode iOS Simulator Debug 构建已执行；真实 Duo 的外屏、内屏、折叠、键盘、多 Scene、PhotoPicker、MediaViewer 和性能场景仍记录为 `pending_device`，不能用普通模拟器结果替代。

本轮剩余源码边界已补齐：AutoScale 新布局使用 owning View 的局部安全矩形，权限 Header 提供 `cellHeight(forWidth:)`，PhotoPicker fakeNav 使用 Sheet 实际 pullbar frame 并比较更新 inset，EyeTracking 暴露 `calibrationState`、`calibrate(screenSizeMeters:)` 与失效降级入口。默认物理尺寸仍是 `estimated`，未完成真实设备标定前不宣称精确眼动坐标。

