<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: feature/pr56-pr60-rc-ci-security-20261030
Source revision: 2441530327017e893373eea63d9c87cd4c164ebe
Source version: 5.69.0
Source inputs digest: d55d40519638e28785124558612fcb09551665299151a4effe0a7b983163cfcb
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-30T04:24:44Z
-->

# MainActor Runtime Validation

Source inputs digest: `be49301643b6a2a5bce655f92ca8b930fa1c9b9bedc3f191dcc21a85be55d45d`

This report intentionally does not claim runtime proof. Execute the listed flows with Instruments or on a real iOS device before the 6.0 release gate.

| Flow | Status | Required evidence |
| --- | --- | --- |
| PTVideoCoverCache | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| PTVideoThumbnailService | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| PTLoadImageFunction | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| MediaViewer | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| PTRichText media | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| VideoEditor | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |
| ImageEditor | REQUIRES_INSTRUMENTS_OR_DEVICE | MainActor time, off-main work, cancellation, and memory trace |

## Acceptance rule

`REQUIRES_INSTRUMENTS_OR_DEVICE` is a release blocker until an attached Instruments trace or real-device run is recorded by the host project.
