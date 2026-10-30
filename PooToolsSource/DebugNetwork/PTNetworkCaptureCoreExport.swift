// A source-compatible SwiftPM facade: existing clients importing PooToolsDEBUG
// continue to see canonical PTNetworkCapture* types after PR23 extraction.
// CocoaPods compiles capture sources directly into DEBUG and needs no re-export.
#if SWIFT_PACKAGE
@_exported import PToolsDebugNetworkCore
#endif
