// The stable 5.x import surface continues exposing Debug event types even
// after their mutable owner was removed from the UIKit aggregate.
#if SWIFT_PACKAGE
@_exported import PToolsDebugCore
#endif
