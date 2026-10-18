# PTLayout 3.0 / PTools 5.67.0

<!-- English: This guide documents the native product boundary and its evidence level. -->
<!-- Español: Esta guía documenta el límite del producto nativo y su nivel de evidencia. -->
<!-- 中文：本文档记录原生产品边界和证据等级。 -->

## Product boundary

`PToolsConstraintLayout` is a UIKit/Foundation-only SwiftPM target and the `PooTools/ConstraintLayout` CocoaPods subspec. It does not import SnapKit, `ptools`, `PToolsUIFoundation`, or `PooToolsLayout`.

`PooToolsLayout` remains the existing CollectionViewPagingLayout product. It is not renamed, replaced, or merged with the Auto Layout engine.

## Basic usage

```swift
import UIKit
import PToolsConstraintLayout

@MainActor
func install(container: UIView, title: UILabel) {
    container.addSubview(title)
    title.ptLayout.makeConstraints { make in
        make.top.equalTo(container.safeAreaLayoutGuide).offset(12)
        make.leading.trailing.equalTo(container).inset(16)
        make.height.equalTo(44)
    }
}
```

The return value is `PTLayoutResult`. Existing call sites may ignore it because the mutation methods are `@discardableResult`; new code should inspect failures when the view hierarchy is dynamic.

## Safety contract

- Missing superview, cross-tree references, orphan guides, invalid multipliers, and update mismatches return a typed failure.
- A failed transaction installs zero constraints.
- `width`/`height` constant constraints can succeed before a view is added to a parent.
- `remakeConstraints` validates the replacement before removing the old PTLayout group.
- `removeConstraints` removes only constraints owned by PTLayout, not SnapKit or storyboard constraints.
- The default diagnostic mode reports `PTL001`–`PTL009`; the aggregate PTools bridge can forward failures to `PTNSLogConsole`.

## Compatibility

Existing `.snp` code remains available in its legacy boundary. It is not protected by PTLayout's preflight validation. The native product does not expose SnapKit types in its public API.

## Platform matrix

| Platform | Status | Boundary |
| --- | --- | --- |
| iOS 17+ | Supported | UIKit views, safe area, keyboard guide, RTL and Duo-sized containers |
| iPadOS 17+ | Supported | Split/floating keyboard behavior must be validated by the host app |
| visionOS | Conditional | UIKit availability and target import must be validated in the consuming package |
| watchOS | Not a UIKit target | Use Foundation-only PTools products; do not import this product |
| macOS | Conditional | Use only when the consumer supplies a UIKit-compatible target; AppKit is not silently substituted |

Performance reports intentionally distinguish instrumentation from measured results. No speed advantage is claimed until the same host runs all engine baselines.

## Diagnosing a failure

```swift
let result = label.ptLayout.makeConstraints { make in
    make.top.equalToSuperview()
}
if let issue = result.issue {
    print(issue.code.rawValue, issue.fileID, issue.line, issue.suggestion)
}
```

English: Runtime and device validation remain separate from static type-checking.

Español: La validación runtime y en dispositivo es independiente del type-check estático.

中文：运行时和真机验证与静态类型检查分开记录。
