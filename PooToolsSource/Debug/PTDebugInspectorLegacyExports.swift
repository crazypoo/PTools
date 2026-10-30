// Keep existing consumers importing only PooToolsDEBUG source-compatible
// after the 300+ file local Inspector UI source tree becomes its own target.
// CocoaPods DEBUG still compiles Inspector's original sources once.
#if SWIFT_PACKAGE
@_exported import PToolsDebugInspectorLegacyUI
#endif
