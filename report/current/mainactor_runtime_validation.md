<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: b6875bfcbb5b503f145e05d8bcc101c196cc316e
Source version: 5.60.0
Source inputs digest: eb66b030720b0fd30eb573eff88c7601464f448a455eafda9e1630c8be0309e3
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-03T05:18:13Z
-->

# MainActor Runtime Validation

Source inputs digest: `b72d6a1cc55e0cac8972e0d74e491726ce441e9713cb9c125143019dbb9e9773`

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
