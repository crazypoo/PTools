// Retain the 5.x "import PooToolsDEBUG" API while the immutable inventory
// adapter has one independent SwiftPM compilation owner.
#if SWIFT_PACKAGE
@_exported import PToolsDebugStorageCore
#endif
