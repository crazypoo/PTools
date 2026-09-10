# 5.8 文件尺寸门禁

阈值：超过 1000 行警告，超过 1500 行需要架构例外，超过 2000 行必须登记历史例外，否则失败。

- Warning：10
- Architecture exception：11
- Hard-limit allowlisted：3

| 文件 | 行数 | 分类 |
| --- | ---: | --- |
| `PooToolsSource/Base/PTBaseViewController.swift` | 1620 | architecture_exception |
| `PooToolsSource/Base/PTCollectionView.swift` | 2286 | hard_limit_allowlisted |
| `PooToolsSource/Category/String+PTEX.swift` | 1743 | architecture_exception |
| `PooToolsSource/Category/UIImage+PTEX.swift` | 1396 | warning |
| `PooToolsSource/Category/UIScrollView+PTRefreshEX.swift` | 1426 | warning |
| `PooToolsSource/Category/UIView+PTEX.swift` | 1850 | architecture_exception |
| `PooToolsSource/Debug/CwlDemangle.swift` | 4627 | hard_limit_allowlisted |
| `PooToolsSource/ImageEditor/PTCutViewController.swift` | 1101 | warning |
| `PooToolsSource/ImageEditor/PTEditImageToolEngine.swift` | 1702 | architecture_exception |
| `PooToolsSource/ImageEditor/PTEditImageViewController.swift` | 1552 | architecture_exception |
| `PooToolsSource/ImageEditor/PTStickerManager.swift` | 1053 | warning |
| `PooToolsSource/Inspector/IconKit.swift` | 2684 | hard_limit_allowlisted |
| `PooToolsSource/LocalConsole/LocalConsole.swift` | 1668 | architecture_exception |
| `PooToolsSource/NetWork/Network.swift` | 1999 | architecture_exception |
| `PooToolsSource/PhotoPicker/PTMediaLibViewController.swift` | 1185 | warning |
| `PooToolsSource/Picker/PTBasePickerView.swift` | 1339 | warning |
| `PooToolsSource/Router/PTRouter.swift` | 1056 | warning |
| `PooToolsSource/ScrollBanner/PTBannerView.swift` | 1161 | warning |
| `PooToolsSource/SideMenuControl/PTSideMenuControl.swift` | 1179 | warning |
| `PooToolsSource/TipsView/PTTipsView.swift` | 1227 | warning |
| `PooToolsSource/VideoEditor/PTVideoEditorToolsViewController.swift` | 1623 | architecture_exception |
