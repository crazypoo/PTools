import Foundation
import Alamofire

@MainActor public let AppTestMode = "PT App network environment test".localized()
@MainActor public let AppCustomMode = "PT App network environment custom".localized()
@MainActor public let AppDisMode = "PT App network environment distribution".localized()

public enum NetworkCellularType: String, Sendable {
    case ALL = "Cellular"
    case Cellular2G = "2G"
    case Cellular3G = "3G"
    case Cellular4G = "4G"
    case Cellular5G = "5G"
}

public enum NetWorkStatus: Sendable {
    case unknown
    case notReachable
    case wwan(type: NetworkCellularType)
    case wifi
    case requiresConnection
    case wiredEthernet
    case loopback
    case other
    case checking

    @MainActor public static func valueName(type: NetWorkStatus) -> String {
        switch type {
        case .unknown: return "PT App network status unknow".localized()
        case .notReachable: return "PT App network status disconnect".localized()
        case .wwan(let subType): return subType.rawValue
        case .wifi: return "WIFI"
        case .requiresConnection: return "RequiresConnection"
        case .wiredEthernet: return "WiredEthernet"
        case .loopback: return "loopback"
        case .other: return "Other"
        case .checking: return "Checking"
        }
    }
}

public enum NetWorkEnvironment: Int, Sendable {
    case Development
    case Test
    case Distribution

    @MainActor public static func valueName(type: NetWorkEnvironment) -> String {
        switch type {
        case .Development: return "PT App network environment custom".localized()
        case .Test: return "PT App network environment test".localized()
        case .Distribution: return "PT App network environment distribution".localized()
        }
    }
}

public typealias NetWorkStatusBlock = @Sendable (NetWorkStatus, NetWorkEnvironment) -> Void
public typealias UploadProgress = @MainActor @Sendable (Progress) -> Void
public typealias FileDownloadSuccess = @MainActor @Sendable (AFDownloadResponse<URL?>) -> Void
public typealias FileDownloadFail = @MainActor @Sendable (Error?) -> Void

public var PTBaseURLMode: NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.shared.AppServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    if sliderValue == "2" { return .Test }
    if sliderValue == "3" { return .Development }
    return .Distribution
}

public var PTSocketURLMode: NetWorkEnvironment {
    guard let sliderValue = PTCoreUserDefultsWrapper.shared.AppSocketServiceIdentifier else { return .Distribution }
    if sliderValue == "1" { return .Distribution }
    if sliderValue == "2" { return .Test }
    if sliderValue == "3" { return .Development }
    return .Distribution
}
