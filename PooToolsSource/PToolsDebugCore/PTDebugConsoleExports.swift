// Existing PToolsDebugCore imports continue to expose PTDebugEvent and
// PTDebugEventCenter after Console obtains its independent compilation owner.
#if SWIFT_PACKAGE
@_exported import PToolsDebugConsoleCore
#endif
