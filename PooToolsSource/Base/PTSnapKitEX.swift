// English: Legacy source path kept as a compatibility bridge; the implementation lives in PToolsUIFoundation.
// Español: Se conserva la ruta de código heredada como puente de compatibilidad; la implementación vive en PToolsUIFoundation.
// 中文：保留旧源码路径作为兼容桥接；唯一实现位于 PToolsUIFoundation。

#if !POOTOOLS_SPLIT_UIFOUNDATION && canImport(PToolsUIFoundation)
@_exported import PToolsUIFoundation
#endif
