# PTools Form 3 · Embeddable views, settings rows and transaction-safe updates

Status: implementation branch; host Xcode and device validation required before release.
Scope: PToolsForm only, with two Example catalog entries; YD1688 is intentionally unchanged.

## A. Architecture

- `PTFormEngine` (actor): stable field identity, values, validation, section visibility, snapshots and transactional mutations.
- `PTFormView` (MainActor UIView): owns `PTCollectionView`, focus/keyboard handling, renderer registries, UI events and asynchronous operations. It can be embedded in any UIKit controller without changing the parent inheritance tree.
- `PTFormViewController`: legacy controller entry point, now a light wrapper over `PTFormView`. Existing public initializers and the `form`, `listView`, registry, validation and submit APIs are preserved.
- `PTFormCollectionAdapter` is shared by both usage styles, so the same field IDs and layout semantics apply.

## B. Settings and async interactions

The new field kinds `.action`, `.detail` and `.status` use `PTFormSettingsRowRenderer`. These kinds support `actionID`, `detailText`, `isLoading` and `isDestructive`. `.settings` is a row-aligned configuration preset.

Action rows emit `PTFormEvent.action(PTFormActionID)` without writing a fake Boolean value to the engine. Assign `onActionRequest` to execute an async operation while the row is disabled and loading. Assign `onValueChangeRequest` for guarded toggles; on rejection the persisted value is not changed and the UI returns to the current actor value. Business-layer authorization belongs to the host, not PTools.

```swift
import UIKit
import PToolsForm

let fields = [
    PTFormField(id: "cache", kind: .action, title: "Clear cache",
                actionID: "clear-cache", detailText: "12 MB"),
    PTFormField(id: "biometrics", kind: .toggle, title: "Biometrics",
                value: .boolean(false))
]
let engine = PTFormEngine(fields: fields,
                          sections: [PTFormSection(id: "general",
                                                  fieldIDs: ["cache", "biometrics"])])
let formView = PTFormView(form: engine, configuration: .settings)
formView.onActionRequest = { action in
    if action == "clear-cache" {
        // Perform host-owned asynchronous cache cleanup.
    }
}
formView.onValueChangeRequest = { id, proposed in
    if id == "biometrics" {
        // Validate on the host; throw to reject and restore the old value.
    }
    return proposed
}
```

For a complete form screen, keep using:

```swift
let controller = PTFormViewController(form: engine)
navigationController?.pushViewController(controller, animated: true)
```

## C. Runtime updates

`PTFormMutation` now supports insert/remove/move fields, insert/remove sections, field loading and the existing update operations. `PTFormEngine.performUpdates` preflights the batch to avoid partially applied changes on missing IDs. Call `await formView.performUpdates([...])` from the hosting controller to apply and redraw the collection once.

```swift
try await formView.performUpdates([
    .insertSection(PTFormSection(id: "account", fieldIDs: []), index: 0),
    .insertField(PTFormField(id: "logout", kind: .action,
                             title: "Logout", actionID: "logout"),
                 sectionID: "account", index: nil)
])
```

The diff hash includes text, kind, renderer and action metadata, status and loading attributes. Focused editors are preserved during cell reconfiguration. A real host should nevertheless check complex custom renderers and resizing.

## Verification matrix

Automated source-level XCTest cases added to `PTFormDocumentsFeedbackTests`: independent embedded view/controller, settings accessibility, busy/dirty-state separation, dynamic mutation rollback and visual metadata diff changes.

Catalog scenarios: `input.form3-embedded-settings` and `input.form3-controller`. The demos require the PToolsForm product to be linked; when it is unavailable the catalog displays that limitation.

Required Xcode/host checks before merge:
- SwiftPM independent `PToolsForm` Debug and Release builds, and CocoaPods `PooTools/Form` consumer.
- Text editing across reconfiguration, async-validation cancellation, per-row action double taps and failing biometric-style approval.
- Section insertion/deletion during scrolling; Dynamic Type, VoiceOver, RTL, light/dark appearance, reduced motion.
- iPhone normal size, Duo folded/unfolded, iPad multitasking, safe area + keyboard and multiple scenes.
- Existing Form 2.0 smoke tests and public initializer compatibility.

Do not merge into YD1688 until its real host acceptance checks have passed.
