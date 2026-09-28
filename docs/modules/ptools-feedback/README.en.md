---
module: "PToolsFeedback"
module_id: "ptools-feedback"
language: "en"
status: "stable"
minimum_ios: "17.0"
swift: "6+"
swiftpm_product: "PToolsFeedback"
cocoapods_subspec: "Feedback"
source: "PooToolsSource/PToolsFeedback"
category: "p2-feedback"
last_reviewed: "2026-09-28"
canonical: true
canonical_source: "self"
documentation_version: "5.56.2"
---

# PToolsFeedback

## 1. Overview

PToolsFeedback is a PTools p2-feedback module. This guide is generated from the canonical module registry and documents the supported boundary for iOS 17+ and Swift 6+.

## 2. Requirements

- Platform: iOS 17.0+
- Swift: 6+
- Category: `p2-feedback`
- Status: `stable`

## 3. Installation

Swift Package Manager:

```swift
import PToolsFeedback
```

CocoaPods:

```ruby
pod 'PooTools/Feedback'
```

## 4. Import

```swift
import PToolsFeedback
```

## 5. Quick Start

Use the smallest published product or subspec. The registry name is `PToolsFeedback`; do not infer an unpublished product or dependency.

## 6. Core Concepts

The public boundary is value-first where possible. Direct dependencies recorded by the registry: None declared by the registry..

## 7. Main APIs

Use only stable public symbols documented by the module source. Complete symbol data belongs to generated API reports, not hand-maintained prose.

## 8. Common Use Cases

Typical uses should stay within this module's category and should not duplicate a canonical implementation from another PTools module.

## 9. Advanced Usage

Inject a provider or policy only when the public API exposes one. Avoid reaching into internal state or private UIKit ownership.

## 10. Swift Concurrency

UI work is `@MainActor`; shared values should be `Sendable`; cancellation must propagate through the owning `Task`.

## 11. Lifecycle

Follow the module's start/stop, register/unregister, and scene lifecycle contract. Do not retain a host controller longer than necessary.

## 12. Error Handling

Handle public errors explicitly. Recoverable failures should return control to the host; permissions and configuration failures must not be hidden.

## 13. Permissions / Entitlements / Info.plist

This module has no additional requirement unless its source exposes a platform permission, entitlement, background mode, or Info.plist key.

## 14. Simulator Behavior

Simulator behavior may differ for hardware, notifications, background execution, audio, camera, or extension hosts. Use a real device for those capabilities.

## 15. Accessibility

UI integrations must preserve Dynamic Type, VoiceOver, Reduce Motion, Reduce Transparency, and RTL behavior.

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
