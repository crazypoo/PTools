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

public struct PTMapAnnotation: Codable, Hashable, Sendable {
    public let id: String
    public let title: String?
    public let subtitle: String?
    public let coordinate: PTMapCoordinate

    public init(id: String,
                title: String? = nil,
                subtitle: String? = nil,
                coordinate: PTMapCoordinate) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

public struct PTMapSearchResult: Codable, Hashable, Sendable {
    public let query: String
    public let places: [PTMapPlace]

    public init(query: String, places: [PTMapPlace]) {
        self.query = query
        self.places = places
    }
}

public enum PTMapTransport: String, Codable, Hashable, Sendable {
    case automobile
    case walking
    case transit
    case cycling
}

public struct PTMapETA: Codable, Hashable, Sendable {
    public let distance: Double
    public let expectedTravelTime: TimeInterval
    public let arrivalDate: Date?

    public init(distance: Double,
                expectedTravelTime: TimeInterval,
                arrivalDate: Date? = nil) {
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.arrivalDate = arrivalDate
    }
}

public struct PTMapRouteStep: Codable, Hashable, Sendable {
    public let instruction: String
    public let distance: Double
    public let expectedTravelTime: TimeInterval
    public let coordinates: [PTMapCoordinate]

    public init(instruction: String,
                distance: Double,
                expectedTravelTime: TimeInterval,
                coordinates: [PTMapCoordinate] = []) {
        self.instruction = instruction
        self.distance = distance
        self.expectedTravelTime = expectedTravelTime
        self.coordinates = coordinates
    }
}

public struct PTMapRouteDetails: Codable, Hashable, Sendable {
    public let route: PTMapRoute
    public let eta: PTMapETA
    public let steps: [PTMapRouteStep]
    public let alternatives: [PTMapRoute]

    public init(route: PTMapRoute,
                eta: PTMapETA,
                steps: [PTMapRouteStep] = [],
                alternatives: [PTMapRoute] = []) {
        self.route = route
        self.eta = eta
        self.steps = steps
        self.alternatives = alternatives
    }
}

public enum PTMapExternalProvider: String, Codable, Hashable, Sendable {
    case apple
    case google
    case googleUniversalLink
}

public protocol PTExternalMapProvider: Sendable {
    var identifier: String { get }
    func url(for coordinate: PTMapCoordinate, label: String?) -> URL?
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
