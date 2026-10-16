<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 006e0ce7bc03d83a9975c28592ab72db02d84f0c
Source version: 5.65.5
Source inputs digest: fa638819a550cc10bcdfd4727a19c488d9d0849430ac11af4a37a71118a01d31
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-16T16:50:09Z
-->

# MainActor Runtime Validation

Source inputs digest: `ef2098531aaf41e4e524615cc4582096db59b7de2b0ce88ee2709daef65df378`

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
