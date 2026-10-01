// English: Machine-readable DebugNetwork regression scenarios keep the final acceptance matrix explicit.
// Español: Los escenarios legibles por máquina mantienen explícita la matriz final de aceptación de DebugNetwork.
// 中文：用机器可读的场景明确 DebugNetwork 最终验收矩阵。

import Foundation

public enum PTNetworkRegressionScenario: String, CaseIterable, Hashable, Sendable {
    case get
    case postJSON
    case form
    case upload
    case download
    case redirect
    case cancel
    case timeout
    case clientError
    case serverError
    case largeRequest
    case largeResponse
    case chunkedResponse
    case gzip
    case httpBodyStream
    case multiScene
    case debugOnOffParity
    case burstPerformance
    case realHost
}

public enum PTNetworkBodyStoreScenario: String, CaseIterable, Hashable, Sendable {
    case previewExact
    case previewPlusOne
    case fileThreshold
    case absoluteLimit
    case temporaryCleanup
    case memoryBudget
    case diskBudget
    case fiveHundredRecords
    case oneThousandRecords
    case eviction
    case concurrentInsert
    case concurrentFinalize
}

public enum PTNetworkRegressionMatrix {
    public static let capture: [PTNetworkRegressionScenario] = PTNetworkRegressionScenario.allCases
    public static let bodyAndStore: [PTNetworkBodyStoreScenario] = PTNetworkBodyStoreScenario.allCases
}
