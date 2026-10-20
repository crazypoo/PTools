---
module: "PooToolsCodeView"
module_id: "poo-tools-code-view"
language: "en"
status: "stable"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "PooToolsCodeView"
cocoapods_subspec: "CodeView"
source: "PooToolsSource/CodeView"
category: "ui-leaf"
last_reviewed: "2026-10-20"
canonical: true
canonical_source: "self"
product_version_source: "repository:VERSION"
document_schema_version: 1
---

# PooToolsCodeView

## 1. Overview

PooToolsCodeView is the SwiftPM-facing name of the stable PTools UI-leaf module. This guide is generated from the canonical module registry and documents the supported boundary for iOS 17+ and Swift 6+.

## 2. Requirements

- Platform: iOS 17.0+
- Swift: 6+
- Category: `ui-leaf`
- Status: `stable`
- Platform boundary: this UIKit view is provided for iOS; no watchOS or macOS UIKit target is exposed, and visionOS support is not claimed by this module.

## 3. Installation

Swift Package Manager:

```swift
import PooToolsCodeView
```

CocoaPods:

```ruby
pod 'PooTools/CodeView'
```

## 4. Import

```swift
import PooToolsCodeView
```

## 5. Quick Start

Use `PooToolsCodeView` from SwiftPM or `PooTools/CodeView` from CocoaPods. The module exposes local generated code, host-supplied text, and host-supplied images.

## 6. Core Concepts

The module depends on the PTools Core boundary only. It does not download or decode remote media; the host owns any network work and supplies the resulting text or image.

## 7. Main APIs

Use `PTCodeView(numberOfCodes:numberOfLines:changeTimes:)` for local generation; `changeTimes` is the automatic refresh interval in seconds and `0` disables it. Use `setCode(_:)` for external text, `setCodeImage(_:)` for an image, and `requestRefresh()` for a programmatic refresh. External refreshes arrive through `onRefreshRequested`; local refreshes arrive through `codeBlock`.

```swift
let codeView = PTCodeView(numberOfCodes: 4, numberOfLines: 3, changeTimes: 0)
codeView.setCode("SERVER-001")
codeView.onRefreshRequested = { view, reason in
    view.setCode("SERVER-002")
}
```

## 8. Common Use Cases

Typical uses should stay within this module's category and should not duplicate a canonical implementation from another PTools module.

## 9. Advanced Usage

Inject a provider or policy only when the public API exposes one. Avoid reaching into internal state or private UIKit ownership.

## 10. Swift Concurrency

UI work is `@MainActor`. `PTCodeRefreshReason` is `Sendable`; external callbacks stay on the view's actor. Automatic refresh is cancelled when the view leaves its window or the application enters the background.

## 11. Lifecycle

Follow the module's start/stop, register/unregister, and scene lifecycle contract. Do not retain a host controller longer than necessary.

## 12. Error Handling

Handle public errors explicitly. Recoverable failures should return control to the host; permissions and configuration failures must not be hidden.

## 13. Permissions / Entitlements / Info.plist

This module has no additional requirement unless its source exposes a platform permission, entitlement, background mode, or Info.plist key.

## 14. Simulator Behavior

Simulator behavior may differ for hardware, notifications, background execution, audio, camera, or extension hosts. Use a real device for those capabilities.

## 15. Accessibility

The view exposes a container-level VoiceOver action named “刷新验证码” and keeps the image view non-interactive. Hosts should provide an accessible label when the code is not safe to announce.

## 16. Performance

Keep work off the main actor when it is not UI work. Bound memory, cache, media, and network resources according to the module's owning service.

## 17. Privacy & Security

Do not log tokens, cookies, credentials, private payloads, or full user input. Use the module's typed boundary for sensitive data.

## 18. Integration with Other PTools Modules

Prefer the existing PTools canonical services and adapters instead of creating a parallel cache, router, permission, or scheduler.

## 19. Migration

Compatibility wrappers remain available during 5.x. New code should use the canonical entry documented by the current registry.

## 20. Troubleshooting

If behavior is unexpected, verify module selection, target membership, scene context, permissions, cancellation, and the generated reports before changing source.

## 21. Example Project

See the repository Example project and the domain test registry for executable coverage. Host-specific entitlements remain the host's responsibility.

## 22. Related Documentation

[Documentation index](../../index/README.en.md) · [Architecture](../../architecture/ARCHITECTURE.md) · [Quality](../../maintainers/QUALITY.md)
