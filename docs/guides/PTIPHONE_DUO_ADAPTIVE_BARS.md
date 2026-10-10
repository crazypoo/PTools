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

## 自定义导航页

`PTBaseViewController` 仍可覆写 `pt_Title`、`preferredNavigationBarStyle()`、`prefersLargeTitle()` 等旧 API。非基类控制器可以实现 `PTAdaptiveNavigationMetadataProviding`，只提供标题或轴偏好，不必改变旧的 `PTNavigationConfigurable`。

导航和 TabBar 的状态不会因尺寸变化而重建：当前 selected index、导航栈、Badge、Lottie 内容、输入文本和 accessory 状态由原控制器继续持有。系统模式下，PTools 会为 `PTTabBarItemConfig` 写入语义标题，并在缺少系统图标时使用安全的 `circle` fallback；原有自定义内容仍由旧 renderer 使用。

## 几何和安全区规则

- 所有布局取当前宿主 View 的 bounds 和 `safeAreaInsets`，四边分别处理。
- iOS 27.1+ 只在 UIKit 给出 `.leading` / `.trailing` 时启用垂直轴；`unspecified` 不被猜成某一侧。
- `occlusion` 和 `division` 的 active reserved regions 会进入几何快照，rail 不放置在禁区内。
- 重要操作的最小触摸目标为 44 pt；空间不足时优先保留返回/关闭、主要操作和当前选中 Tab，其余进入 overflow。
- 不使用 `UIScreen.main`、设备型号、`UIDevice.isFaceIDCapable` 或固定屏幕尺寸推断 Duo。

## Debug 观察

开发期可以打开：

```swift
showsAdaptiveBarDebugOverlay = true
```

`adaptiveBarGeometry` 提供当前值类型快照，包括 `axis`、`renderer`、`edge`、`contentSafeRect`、`navItemsRect`、`tabItemsRect`、`accessoryRect`、可见 Tab 和 overflow Tab。DEBUG overlay 会绘制内容、导航、Tab、accessory 和 reserved region 矩形，并输出坐标摘要；Release 不绘制这些诊断内容。

## Demo 入口

Example 的 `Navigation & Routing` 分类新增 `iPhone Duo Adaptive Bars`，覆盖：

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

## 验证边界

几何单测使用可注入的 bounds、safe area、edge 和 reserved region，不要求实体设备。完整 Xcode Simulator Debug / Release 构建用于验证 iOS 17+ 编译、旧横向回归和 Example 入口。

真实 iPhone Duo 的外屏、内屏、折叠转场、相机遮挡区、Live Activity、PiP、分屏和硬件触控仍需要在 Apple 提供的 Duo Simulator / Device Hub 或实体设备上验收；普通 iPhone 模拟器不能证明真实折叠行为。

