// English: The adapter exposes read-only business metadata without changing request policy.
// Español: El adaptador expone metadatos de negocio de solo lectura sin cambiar la política de la solicitud.
// 中文：适配器只读暴露业务元数据，不改变请求策略。

import Foundation

public enum PTNetworkModuleCaptureAdapter {
    @discardableResult
    public static func record(request: PTNetworkRequestSnapshot,
                              response: PTNetworkCaptureResponseSnapshot?,
                              timing: PTNetworkTiming,
                              metrics: PTNetworkTaskMetricsSnapshot? = nil,
                              error: PTNetworkCaptureError? = nil,
                              completion: PTNetworkCaptureCompletion,
                              fetchSource: PTNetworkFetchSource? = .network,
                              retryCount: Int = 0) async -> PTNetworkCaptureRecord {
        let record = PTNetworkCaptureRecord(request: request,
                                            response: response,
                                            timing: timing,
                                            metrics: metrics,
                                            error: error,
                                            source: .ptoolsNetwork,
                                            completion: completion,
                                            phase: .finalized,
                                            fetchSource: fetchSource,
                                            retryCount: retryCount)
        return await PTNetworkCaptureCenter.shared.record(record)
    }
}
