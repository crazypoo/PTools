// Opt-in, Debug-only Bonjour rendezvous for the existing authenticated TLS bridge.
// Advertisements are untrusted hints. No pairing secrets travel through mDNS.
@preconcurrency import Foundation

#if os(iOS)

public struct PTStudioDiscoveredPeer: Identifiable, Equatable, Sendable {
    /// Persistent, public Studio installation UUID. Not a credential.
    public let id: String
    public let name: String
    public let tlsHost: String
    public let port: Int

    public var endpoint: URL? {
        URL(string: "https://\(tlsHost):\(port)/v1/events")
    }
}

public enum PTStudioDiscoveryError: Error, Equatable {
    case disabledInRelease
    case missingLocalNetworkDescription
    case missingBonjourServices
    case peerNotDiscovered
}

/// Search is deliberately inactive until the host app enables Debug diagnostics.
/// The host Info.plist must declare NSBonjourServices = [_ptstudio._tcp]
/// and NSLocalNetworkUsageDescription.
@MainActor
public final class PTStudioBonjourDiscovery: NSObject, @preconcurrency NetServiceBrowserDelegate, @preconcurrency NetServiceDelegate {
    public static let serviceType = "_ptstudio._tcp."
    public private(set) var peers: [PTStudioDiscoveredPeer] = []
    public var onChange: (@MainActor ([PTStudioDiscoveredPeer]) -> Void)?
    public var onError: (@MainActor (String) -> Void)?

    private let browser = NetServiceBrowser()
    private var services: [ObjectIdentifier: NetService] = [:]
    private var resolved: [ObjectIdentifier: PTStudioDiscoveredPeer] = [:]
    private var isBrowsing = false

    public override init() {
        super.init()
        browser.delegate = self
    }

    public func start() throws {
        #if !DEBUG
        throw PTStudioDiscoveryError.disabledInRelease
        #else
        guard Bundle.main.object(forInfoDictionaryKey: "NSLocalNetworkUsageDescription") as? String != nil else {
            throw PTStudioDiscoveryError.missingLocalNetworkDescription
        }
        let declared = Bundle.main.object(forInfoDictionaryKey: "NSBonjourServices") as? [String] ?? []
        guard declared.contains("_ptstudio._tcp") else {
            throw PTStudioDiscoveryError.missingBonjourServices
        }
        guard !isBrowsing else { return }
        isBrowsing = true
        browser.searchForServices(ofType: Self.serviceType, inDomain: "local.")
        #endif
    }

    public func stop() {
        guard isBrowsing else { return }
        isBrowsing = false
        browser.stop()
        for service in services.values {
            service.stop()
            service.delegate = nil
        }
        services.removeAll()
        resolved.removeAll()
        publish()
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService,
                                  moreComing: Bool) {
        guard isBrowsing else { return }
        let key = ObjectIdentifier(service)
        services[key] = service
        service.delegate = self
        service.resolve(withTimeout: 10)
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService,
                                  moreComing: Bool) {
        let key = ObjectIdentifier(service)
        services.removeValue(forKey: key)?.stop()
        resolved.removeValue(forKey: key)
        if !moreComing { publish() }
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser,
                                  didNotSearch errorDict: [String: NSNumber]) {
        onError?("Bonjour search failed: \(errorDict)")
    }

    public func netServiceDidResolveAddress(_ sender: NetService) {
        guard isBrowsing, services[ObjectIdentifier(sender)] != nil,
              let txtData = sender.txtRecordData() else { return }
        let txt = NetService.dictionary(fromTXTRecord: txtData)
        func value(_ key: String) -> String? {
            txt[key].flatMap { String(data: $0, encoding: .utf8) }
        }
        guard value("v") == "1",
              let rawID = value("id"), let uuid = UUID(uuidString: rawID),
              let host = value("host")?.lowercased(),
              Self.isLocalHost(host),
              sender.port > 0, sender.port <= 65535 else { return }
        resolved[ObjectIdentifier(sender)] = PTStudioDiscoveredPeer(
            id: uuid.uuidString.lowercased(), name: sender.name,
            tlsHost: host, port: sender.port)
        publish()
    }

    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        resolved.removeValue(forKey: ObjectIdentifier(sender))
        publish()
    }

    /// Never follow an unauthenticated TXT host onto the public internet.
    /// Final authentication still requires both the saved leaf pin and bearer token.
    public static func isLocalHost(_ host: String) -> Bool {
        guard host.count <= 253, !host.isEmpty,
              !host.contains(":"), !host.contains("/"), !host.contains("%"),
              !host.contains("\\") else { return false }
        if host.hasSuffix(".local") {
            return host.count > 6 &&
                host.utf8.allSatisfy {
                    (48...57).contains($0) || (65...90).contains($0) ||
                    (97...122).contains($0) || $0 == 45 || $0 == 46
                }
        }
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
            .compactMap { UInt8($0) }
        guard parts.count == 4 else { return false }
        let a = parts[0], b = parts[1]
        return a == 10 || (a == 172 && (16...31).contains(b)) ||
            (a == 192 && b == 168) || (a == 169 && b == 254) ||
            (a == 127 && b == 0)
    }

    private func publish() {
        let next = resolved.values.sorted { $0.id < $1.id }
        if next != peers {
            peers = next
            onChange?(next)
        }
    }
}

/// Automatic reconnection is opt-in. A Bonjour discovery by itself NEVER
/// authorizes traffic capture or new pairing.
@MainActor
public final class PTStudioAutoConnectionManager {
    public static let shared = PTStudioAutoConnectionManager()
    public let discovery = PTStudioBonjourDiscovery()
    public private(set) var currentPeer: PTStudioDiscoveredPeer?
    public var isEnabled: Bool { enabled }
    public var onPeersChanged: (@MainActor ([PTStudioDiscoveredPeer]) -> Void)?
    /// Called when a bridge transport starts. The host may enable capture here.
    public var onBridgeStarted: (@MainActor () -> Void)?
    /// Called after the managed bridge is stopped. The host may disable capture.
    public var onBridgeStopped: (@MainActor () -> Void)?
    public var onError: ((String) -> Void)?

    private var enabled = false
    private var ownsBridge = false
    private var requestedPeer: PTStudioDiscoveredPeer?
    private var generation = 0
    private var transition: Task<Void, Never>?

    public init() {
        discovery.onChange = { [weak self] peers in
            self?.reconcile()
            self?.onPeersChanged?(peers)
        }
        discovery.onError = { [weak self] message in self?.onError?(message) }
    }

    public func start() throws {
        #if !DEBUG
        throw PTStudioDiscoveryError.disabledInRelease
        #else
        guard !enabled else { return }
        try discovery.start()
        enabled = true
        reconcile()
        #endif
    }

    /// Refresh mDNS after foregrounding or a Wi-Fi change.
    public func refresh() throws {
        guard enabled else { return }
        discovery.stop()
        try discovery.start()
        reconcile()
    }

    /// User must select a discovered Studio and enter its token + leaf pin
    /// from the Mac's pairing UI before this method is called.
    public func approvePairing(peerID: String, token: String, fingerprintHex: String) throws {
        guard discovery.peers.contains(where: { $0.id == peerID }) else {
            throw PTStudioDiscoveryError.peerNotDiscovered
        }
        let credentials = try PTStudioPairingCredentials(
            bearerToken: token, leafCertificateSHA256Hex: fingerprintHex)
        try PTStudioPairingKeychain.save(credentials, account: peerID)
        reconcile(force: true)
    }

    public func revokePairing(peerID: String) {
        PTStudioPairingKeychain.revoke(account: peerID)
        reconcile(force: true)
    }

    public func stop() {
        enabled = false
        discovery.stop()
        generation &+= 1
        transition?.cancel()
        requestedPeer = nil
        let hadManagedBridge = ownsBridge
        ownsBridge = false
        currentPeer = nil
        let previous = transition
        transition = Task { [weak self] in
            await previous?.value
            if hadManagedBridge {
                await PTStudioBridge.shared.stop()
                self?.onBridgeStopped?()
            }
        }
    }

    private func reconcile(force: Bool = false) {
        guard enabled else { return }
        let desired = discovery.peers.first {
            PTStudioPairingKeychain.load(account: $0.id) != nil
        }
        if !force, desired == requestedPeer { return }
        requestedPeer = desired
        generation &+= 1
        let run = generation
        let previous = transition
        transition?.cancel()
        transition = Task { [weak self] in
            await previous?.value
            guard let self, run == self.generation, self.enabled else { return }
            if self.ownsBridge {
                await PTStudioBridge.shared.stop()
                self.ownsBridge = false
                self.currentPeer = nil
                self.onBridgeStopped?()
            }
            guard run == self.generation, self.enabled,
                  let peer = desired,
                  let credentials = PTStudioPairingKeychain.load(account: peer.id),
                  let endpoint = peer.endpoint else { return }
            do {
                let transport = try PTStudioHTTPSPushTransport(
                    endpoint: endpoint, credentials: credentials)
                try await PTStudioBridge.shared.start(
                    using: transport,
                    configuration: PTStudioBridgeConfiguration(isEnabled: true))
                guard run == self.generation, self.enabled else {
                    await PTStudioBridge.shared.stop()
                    return
                }
                self.ownsBridge = true
                self.currentPeer = peer
                self.onBridgeStarted?()
            } catch {
                if run == self.generation {
                    self.onError?("Studio reconnect to \(peer.name) failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

#endif // os(iOS)
