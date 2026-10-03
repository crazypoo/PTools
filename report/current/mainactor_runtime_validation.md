<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: e9ae991e3411ea728be377c2e82b1635af069c05
Source version: 5.60.0
Source inputs digest: 51cdd4d720ea7bc9b8f86737ccd98a49ddcefa19dddcdcde04ad78c0e9d9a3be
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-03T12:21:13Z
-->

# MainActor Runtime Validation

Source inputs digest: `628961a34e0f68d0982b842758487e3768224a68decf14e43be0360d8bc59a98`

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
