# PTools Example 模块页面与迁移索引

当前示例工程是一个可运行的模块展厅，不把每个功能复制成独立 App。5.9.7 为每个逻辑模块登记
入口页面、覆盖范围和回归重点；这样既能保持示例工程的启动路径稳定，也能让宿主项目按模块迁移。

## 示例工程入口

| 层级 | 当前入口 | 作用 |
|---|---|---|
| Scene | `PooTools/SceneDelegate.swift` | 创建 `PTSideMenuControl`、`PTTestTabbarViewController` 和菜单页 |
| TabBar | `PooTools/PTTestTabbarViewController.swift` | 创建多个 `PTBaseNavControl`，验证 TabBar、导航栏和登录拦截 |
| 主页面 | `PooTools/PTFuncNameViewController.swift` | 以 `PTCollectionView` 展示网络、多媒体、本机、UIKIT、Route、Encryption 分组 |
| 详情页 | `PooTools/PTFuncDetailViewController.swift` | 按示例名称加载具体功能页面 |
| 菜单页 | `PooTools/PTSideController.swift` | 验证 SideMenu、LocalConsole、Inspector 和 Sheet 页面 |

## 逻辑模块页面

| 页面 | 当前示例入口 | 主要验证内容 | 推荐迁移入口 |
|---|---|---|---|
| Core | `PTFuncNameViewController` 的通用行和 `PTFuncDetailViewController` | `PTBaseViewController`、`PTUtils`、语言、状态栏、通用 Category | `PooTools/Core` / SPM `ptools` |
| Navigation | `PTTestTabbarViewController`、`PTTestVC`、`PTRouteViewController` | `PTBaseNavControl`、push/pop、interactive-pop、场景解析 | `PTBaseNavControl`、`PTSceneContext`、类型化 Router 入口 |
| TabBar | `PTTestTabbarViewController`、`PTTabBarTestOneViewController` | TabBar 快照、徽标、Lottie、Accessory 和页面选择 | `PTBaseTabBarViewController`、`PTTabBarView` |
| Collection | `PTFuncNameViewController`、`PTImageListViewController`、`PTTestVC` | Diffable、预取、骨架、空状态、分页和稳定 ID | `PTCollectionView`、`PTListViewController` |
| Network | `PTFuncDetailViewController` 的“局域网传送”和网络行 | Network 状态、请求日志、上传/下载和取消 | `PooToolsNetWork`、类型化 Codable 请求 |
| Media | `PTFuncDetailViewController` 的图片、视频、签名、识字和媒体选择 | 图片加载、视频缩略图、媒体保存、权限和生命周期 | `PTLoadImageFunction`、`PTVideoThumbnailService`、`PTMediaSaveService` |
| Picker | `PTFuncDetailViewController` 的媒体选择、`PTImageListViewController` | 系统 ImagePicker 与 PhotoPicker 的边界、取消和结果状态 | `PTSystemMediaPicker` 或 `PTMediaLibViewController` |
| Alert | `PTFuncNameViewController` 的 Alert、反馈和 Menu 行 | 系统样式、按钮顺序、超长按钮、键盘和无障碍 | `UIAlertController+PTEX`、`PTCustomerAlertController`、`PTActionSheetController` |
| Permission | `PTPermissionViewController`、`PTPermissionSettingViewController` | 授权、拒绝、受限状态和 MainActor completion | `PTPermission` 及对应权限模块 |
| Theme | `PTFuncNameViewController` 的语言、DarkMode 行和 `PTDarkModeControl` | trait 变化、透明度、动态颜色和 String Catalog | `PTTheme`、`PTVisualStyleResolver`、`PTLanguage` |
| Debug | `PTSideController` 的 LocalConsole/Inspector 入口 | scene-scoped 调试窗口、日志、视图检查和崩溃诊断 | `PooToolsDEBUG`、`LocalConsole.console(for:)` |
| Accessibility | 上述页面的动态字体、Reduce Motion 和 Reduce Transparency 场景 | 视觉策略、动画降级、标签和可操作区域 | `PTUIAccessibility` 与各组件的无障碍入口 |

## 迁移时的最小路径

### Core / Navigation

```swift
@MainActor
final class ExampleViewController: PTBaseViewController {
    override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        .solid(.systemBackground)
    }
}
```

页面创建后使用宿主自己的导航容器；不要在业务页面重复安装导航代理或读取全局 key window。

### Collection

```swift
@MainActor
final class ExampleListViewController: PTListViewController {
    override func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        return configuration
    }
}
```

列表只保留一个 `PTCollectionView`，不要为了类表格页面再维护一套独立 `UITableView` 数据源。

### Media / Picker

轻量单媒体选择使用 `PTSystemMediaPicker`；多选、原图、Live Photo、编辑和 iCloud 进度使用
`PTMediaLibViewController`。两条路径都必须在页面退出时处理取消和结果生命周期。

### Debug

```swift
let console = LocalConsole.console(for: view.window?.windowScene)
console.isVisiable = true
```

旧的 `LocalConsole.shared` 仍然兼容，但新宿主页面应传入明确的 `UIWindowScene`，避免多窗口时
日志面板显示到错误的场景。

## 5.9.7 回归清单

- [ ] 从 `SceneDelegate` 冷启动，主页面和三个 Tab 均可进入。
- [ ] A → B → C push 后，点击返回和 interactive-pop 都恢复上一页导航栏样式。
- [ ] Collection 页面快速滚动、预取、骨架和空状态不会回写旧 Cell。
- [ ] ImagePicker/PhotoPicker 分别验证取消、无权限、单选、多选和 iCloud 资源。
- [ ] Alert/ActionSheet 的长按钮列表可滚动，取消按钮位于底部且只回调一次。
- [ ] Language、DarkMode、Reduce Motion、Reduce Transparency 和 Dynamic Type 即时生效。
- [ ] LocalConsole 和 Inspector 在多 Scene 场景显示到发起它们的窗口。
- [ ] Release 环境不输出 token、Cookie、Authorization 或完整响应体。

## 宿主项目迁移边界

本文件只记录仓库内 `PooTools-Example` 的页面覆盖。CrazyDashboard 和其他真实宿主不在本仓库，
必须在 5.9.8 rehearsal 中单独记录编译错误、迁移耗时、运行时差异和待删除 API 调用；不能把本示例
工程通过误认为真实宿主已经迁移完成。
