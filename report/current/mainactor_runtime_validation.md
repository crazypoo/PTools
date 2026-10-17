<!--
Current report metadata.
AUTO-GENERATED FILE.
Repository: crazypoo/PTools
Branch: master
Source revision: 4c508f23263c51171d48163d641a4d808069b81a
Source version: 5.65.6
Source inputs digest: a87b93f96939b4e60d1a69bd9a8ed165943fd5ee7941c29c3cda17d8649b691d
Generator version: 1
Generator: current-report-normalizer
Generated at: 2026-10-16T23:53:38Z
-->

# MainActor Runtime Validation

Source inputs digest: `3328b8be211e3c3c9937fd29e8ab988b14731c2770401e3cb1ee65a67a41c43b`

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
