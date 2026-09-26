# PTools Example 页面与回归索引

`PooTools-Example` 是一个可运行的模块展厅，不把每个功能复制成独立 App。本文件只维护当前
页面入口、模块覆盖和回归重点；一次构建或人工测试的结果写入 `report/`。

## 示例工程入口

| 层级 | 当前入口 | 作用 |
|---|---|---|
| Scene | `PooTools/SceneDelegate.swift` | 创建 `PTSideMenuControl`、TabBar 和菜单页 |
| TabBar | `PooTools/PTTestTabbarViewController.swift` | 创建多个 `PTBaseNavControl`，验证 TabBar 和导航栏 |
| 主页面 | `PooTools/PTFuncNameViewController.swift` | 以 `PTCollectionView` 展示功能分组 |
| 详情页 | `PooTools/PTFuncDetailViewController.swift` | 按示例名称加载具体功能页面 |
| 菜单页 | `PooTools/PTSideController.swift` | 验证 SideMenu、LocalConsole、Inspector 和 Sheet |

## 逻辑模块页面

| 页面 | 当前示例入口 | 主要验证内容 | 推荐入口 |
|---|---|---|---|
| Core | `PTFuncNameViewController`、`PTFuncDetailViewController` | Base、Utils、语言、状态栏、Category | `PooTools/Core` / `ptools` |
| Navigation | `PTTestTabbarViewController`、`PTTestVC`、`PTRouteViewController` | push/pop、interactive-pop、场景解析 | `PTBaseNavControl`、`PTSceneContext` |
| TabBar | `PTTestTabbarViewController`、`PTTabBarTestOneViewController` | 外观快照、徽标、Accessory 和选择 | `PTBaseTabBarViewController` |
| Collection | `PTFuncNameViewController`、`PTImageListViewController`、`PTTestVC` | Diffable、预取、骨架、空状态和分页 | `PTCollectionView`、`PTListViewController` |
| Search | 暂无固定展厅页面 | debounce、竞态取消、History、Suggestion、分页、刷新和导航栏恢复 | `PTSearchViewController`、`PooTools/Search` |
| Network | 网络和局域网传送示例 | 状态、请求日志、上传/下载和取消 | `PooToolsNetWork` |
| Media | 图片、视频、签名、识字和媒体选择示例 | 图片加载、视频缩略图、保存和权限 | `PTLoadImageFunction`、`PTVideoThumbnailService`、`PTMediaSaveService` |
| Rich Text Media | `PTRichText` 媒体示例（见下方代码） | URL/String/UIImage/Data 图片、视频封面、时长、点击和取消 | `PTRichText.image(source:)`、`PTRichText.video(source:)` |
| Picker | 媒体选择和 `PTImageListViewController` | 系统 ImagePicker、PhotoPicker、取消和结果状态 | `PTSystemMediaPicker` 或 `PTMediaLibViewController` |
| Alert | Alert、反馈和 Menu 示例 | 系统样式、按钮顺序、长按钮、键盘和无障碍 | `UIAlertController+PTEX`、`PTCustomerAlertController` |
| Permission | `PTPermissionViewController`、`PTPermissionSettingViewController` | 授权、拒绝、受限和 MainActor completion | `PTPermission` |
| Theme | 语言、DarkMode 和 `PTDarkModeControl` | trait、动态颜色、透明度和 String Catalog | `PTTheme`、`PTLanguage` |
| Debug | `PTSideController` 的调试入口 | Scene-scoped Console、Inspector 和诊断 | `PooToolsDEBUG` |
| Accessibility | 各页面的辅助功能场景 | Dynamic Type、Reduce Motion、Reduce Transparency | `PTUIAccessibility` |

## 最小回归路径

### Core / Navigation

```swift
@MainActor
final class ExampleViewController: PTBaseViewController {
    override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        .solid(.systemBackground)
    }
}
```

页面使用宿主自己的导航容器；不要重复安装导航代理或读取全局 key window。

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

### Media / Picker

轻量单媒体选择使用 `PTSystemMediaPicker`；多选、原图、Live Photo、编辑和 iCloud 进度使用
`PTMediaLibViewController`。两条路径都必须在页面退出时处理取消和结果生命周期。

### Rich Text Media

```swift
@MainActor
func configureRichTextMedia() {
    let richText = PTRichText("图片：")
        .appendingImage(source: imageSource)
        .appendingVideo(source: videoURL,
                        configuration: .init(estimatedAspectRatio: 16.0 / 9.0))
    let loader = PTLoadImageFunction.makeRichTextMediaLoader()
    titleLabel.pt_apply(richText: richText, mediaLoader: loader) { interaction in
        guard case .media(.video(let id)) = interaction else { return }
        presentVideo(id: id)
    }
}
```

`PTRichText` 只渲染占位图和封面，不创建 `AVPlayer`。宿主负责播放；页面复用或替换内容时，渲染器会取消旧媒体请求并忽略过期结果。

### Search

搜索容器不把业务请求写进 `PTSearchBar`。页面只实现 `search(keyword:)` 和 `didSelect(item:at:)`，
搜索基类负责状态、取消、竞态、空状态和列表更新；需要真实宿主数据时再通过 Provider 注入。

### Debug

```swift
let console = LocalConsole.console(for: view.window?.windowScene)
console.isVisiable = true
```

旧的 `LocalConsole.shared` 仍然兼容，但新页面应传入明确的 `UIWindowScene`，避免多窗口时显示到错误场景。

## 回归清单

- [ ] Scene 冷启动、主页面和 Tab 均可进入。
- [ ] A → B → C push 后，点击返回和 interactive-pop 都恢复上一页导航栏样式。
- [ ] Collection 快速滚动、预取、骨架和空状态不会回写旧 Cell。
- [ ] ImagePicker/PhotoPicker 验证取消、无权限、单选、多选和 iCloud 资源。
- [ ] Alert/ActionSheet 长按钮列表可滚动，取消按钮位于底部且只回调一次。
- [ ] Language、DarkMode、Reduce Motion、Reduce Transparency 和 Dynamic Type 即时生效。
- [ ] LocalConsole、Inspector 和 PTInstruments 在多 Scene 显示到发起它们的窗口。
- [ ] Release 不输出 token、Cookie、Authorization 或完整响应体。

## 宿主边界

本文件只记录 `PooTools-Example` 的页面覆盖。CrazyDashboard 和其他真实宿主必须单独记录编译错误、
迁移耗时、运行时差异和待删除 API 调用；Example 通过不能替代真实宿主验收。
