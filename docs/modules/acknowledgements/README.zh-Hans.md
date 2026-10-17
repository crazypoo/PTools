# PTAcknowledgements

`PTAcknowledgementsCore` 是只依赖 Foundation 的离线许可证清单能力，`PToolsAcknowledgements` 是可选 UIKit 列表与详情页。

## 纯数据

```swift
import PToolsAcknowledgementsCore

let manifest = try PTAcknowledgementsProvider.load()
let matches = manifest.search("alamofire")
let summary = manifest.statistics()
let json = try manifest.export(.json)
```

Core 不导入 UIKit、SnapKit 或完整 `ptools`，适合自定义页面、扩展、CLI 和测试。清单由构建期脚本生成，运行时不联网。

## 内置 UIKit 页面

```swift
import PToolsAcknowledgements

navigationController?.pushViewController(
    PTAcknowledgementsViewController(),
    animated: true
)
```

UIKit 页面在可用时优先继承 `PTBaseViewController`，因此复用 PTools 的导航栏、生命周期和状态栏约定；独立 Core/UI 构建没有 PTools UIKit 目标时，才回退为 `UIViewController`。

## 构建期生成

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

将生成的 `PTAcknowledgements.json` 复制到正确的 App bundle。Release/CI 使用 strict 校验；缺失许可证原文、损坏清单和冲突不会静默显示为空列表。
