# PTAcknowledgements

`PTAcknowledgementsCore` is the Foundation-only offline license manifest product. `PToolsAcknowledgements` is the optional UIKit list and detail UI.

## Headless data

```swift
import PToolsAcknowledgementsCore

let manifest = try PTAcknowledgementsProvider.load()
let matches = manifest.search("alamofire")
let summary = manifest.statistics()
let json = try manifest.export(.json)
```

Core does not import UIKit, SnapKit, or the full `ptools` aggregate. It is suitable for custom screens, extensions, CLI tools, and tests. The manifest is generated at build time; runtime network access is not used.

## Built-in UIKit UI

```swift
import PToolsAcknowledgements

navigationController?.pushViewController(
    PTAcknowledgementsViewController(),
    animated: true
)
```

When the PTools UIKit target is available, both list and detail screens explicitly inherit `PTBaseViewController` and reuse its navigation, lifecycle, and status-bar behavior. A standalone Core/UI build falls back to `UIViewController` only when that legacy UI target is unavailable.

## Build-time generation

```sh
bash Scripts/pt_acknowledgements_build.sh
bash Scripts/validate_acknowledgements.sh .build/acknowledgements/PTAcknowledgements.json
```

Copy `PTAcknowledgements.json` into the correct App bundle. Release and CI use strict validation; missing license text, invalid manifests, and conflicts are never silently represented as an empty list.
