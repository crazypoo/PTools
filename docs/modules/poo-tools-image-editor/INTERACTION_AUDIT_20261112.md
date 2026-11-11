# ImageEditor interaction audit — 2026-11-12

Scope: PooToolsSource/ImageEditor (19 Swift source files). Source inspected on master; this document tracks code-confirmed interaction defects and their corrective patches. It does **not** claim simulator or device acceptance.

## Corrected issues

| Area | Failure mode | Correction |
| --- | --- | --- |
| Crop | Draggable edges/corners could escape the image or jump after the snap-to-center animation | Constrain the selection to the viewport and preserve the focal point through zoom changes (earlier patches) |
| Crop | Rubber-band dragging could expose empty content outside the image | Disable bounce in the crop viewport |
| Crop | Fixed bottom layout constants could overlap the ratio strip on devices with different safe areas | Compute the clip frame from the actual ratio-strip geometry |
| Crop | Pending auto-center timer could fire after leaving the crop controller | Invalidate it when the crop screen disappears |
| Crop | Confirm action could interrupt the in-flight 90-degree rotation animation | Guard against completion during rotation |
| Crop | Changing only circle/rectangle status did not always invalidate the editor canvas; circular full-image crop could be exported as unedited | Track circle mode in canvas invalidation and output edit-detection |
| Ratio thumbnails | Mixing SnapKit-managed dimensions and manual frame changes caused layout contention | Resize via retained width/height constraints only; validate thumbnail geometry |
| Crop navigation | Custom transition reported a shorter duration than its animation, and missing preview imagery yielded a blank transition | Consistent duration and non-image fallback |
| Tool list | First selection and deselection left tool icons stale | Refresh both prior and new affected rows, including selecting/deselecting |
| Tool switch | Entering crop left the prior active engine running | Deactivate the previous drawing/adjustment engine |
| Undo/redo | Initial Redo button enabled-state was incorrect; hidden filter/adjust strips attempted to scroll to absent rows | Align Redo state to history count, check strip presence/item count before scrolling |
| Drawing / mosaic | Invalid or failed pan starts could mutate or delete the previous finished stroke | Check active-stroke state before changing or completing a path |
| Sticker resize | Corner gestures never closed their operation | End the operation and release the interactions |
| Sticker rotate | Rotate-handle gestures could leave the operation active; angle wrapping could jump at ±π | End operation and normalize the angle delta |
| Sticker drag | Gesture ownership conflicted with resize/rotate handles | Give handle recognizers priority over sticker and scroll-view pan |
| Sticker trash | Trash UI/delete hit-testing used the parent pan even while resizing or rotating | Show/delete only for an actual drag ending in the trash |
| Sticker history | No-op gesture completion created Undo steps | Compare before/after geometry |
| Sticker text/image | Edit, replacement, and empty-text deletion lacked undoable state snapshots | Store old/new states in the action history |
| Sticker image replacement | Replacing a tall image could unexpectedly push the sticker to an arbitrary canvas y-coordinate, which Undo could not reproduce | Keep the original sticker center instead of applying a non-persisted hardcoded 90pt offset |
| Text editor | Keyboard height was subtracted twice from the safe-area-aligned toolbar | Apply only the overlap beyond existing safe-area inset |
| Text editor | Enter dismissed the text editor rather than inserting a newline | Support multiline editing; use the navigation confirmation action |
| Text editor | Queued text background rendering could restore an already-disabled style; bounds were not adaptive | Cancel/recheck background tasks; pin backdrop to the controller bounds |
| Text editor | Truncating at max character count did not restore caret/style state | Clamp caret and refresh text attributes |

## Regression verification

- Crop geometry tests: Tests/PToolsMediaTests/PTImageCropInteractionTests.swift
- Additional interaction tests: Tests/PToolsMediaTests/PTImageEditorInteractionRegressionTests.swift
- Package target: PToolsMediaTests imports PooToolsImageEditor.
- Remote Git object and changed paths verified after commit. **Xcode build, UIKit unit execution and physical gesture testing remain pending.**
- Device checklist: crop all 8 drag directions at 0/1/max zoom; portrait/landscape and circle ratios; rotate while confirm disabled; tool first-select/deselect; undo filter/adjust while strips are absent; draw/mosaic after cancelled gestures; corner/rotate/drag sticker with trash; edit text and image sticker, Undo then Redo; text keyboard show/hide, multiline and 100-character limit; small screens and iPhone Duo.
