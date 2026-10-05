// English: Foundation-only map value types for geocoding, search, routes, and snapshots.
// Español: Tipos de valor solo de Foundation para geocodificación, búsqueda, rutas y snapshots.
// 中文：地理编码、搜索、路线与快照的 Foundation-only 地图值类型。

import Foundation

public struct PTMapCoordinate: Codable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude; self.longitude = longitude
    }
}

public struct PTMapRegion: Codable, Hashable, Sendable {
    public let center: PTMapCoordinate
    public let latitudeDelta: Double
    public let longitudeDelta: Double
    public init(center: PTMapCoordinate, latitudeDelta: Double = 0.05, longitudeDelta: Double = 0.05) {
        self.center = center; self.latitudeDelta = latitudeDelta; self.longitudeDelta = longitudeDelta
    }
}

public struct PTMapPlace: Codable, Hashable, Sendable {
    public let name: String
    public let address: String?
    public let coordinate: PTMapCoordinate
    public init(name: String, address: String? = nil, coordinate: PTMapCoordinate) {
        self.name = name; self.address = address; self.coordinate = coordinate
    }
}

public struct PTMapRoute: Codable, Hashable, Sendable {
    public let distance: Double
    public let expectedTravelTime: TimeInterval
    public let coordinates: [PTMapCoordinate]
    public init(distance: Double, expectedTravelTime: TimeInterval, coordinates: [PTMapCoordinate]) {
        self.distance = distance; self.expectedTravelTime = expectedTravelTime; self.coordinates = coordinates
    }
}

public enum PTMapError: Error, Sendable, Equatable {
    case notFound
    case unavailable
    case failed(String)
}
