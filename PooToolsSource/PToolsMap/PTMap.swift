// English: Main-actor MapKit adapter for search, geocoding, routes, snapshots, and Apple Maps.
// Español: Adaptador MapKit en MainActor para búsqueda, geocodificación, rutas, snapshots y Apple Maps.
// 中文：基于 MainActor 的 MapKit 适配器，支持搜索、地理编码、路线、快照和 Apple 地图跳转。

import Foundation
import Contacts
import MapKit
#if canImport(UIKit)
import UIKit
#endif
#if SWIFT_PACKAGE
import PToolsMapCore
#endif

@MainActor
public final class PTMapService {
    private let geocoder = CLGeocoder()
    public init() {}

    public func geocode(address: String) async throws -> [PTMapPlace] {
        let placemarks = try await geocoder.geocodeAddressString(address)
        return placemarks.compactMap { (placemark: CLPlacemark) -> PTMapPlace? in
            guard let location = placemark.location else { return nil }
            return PTMapPlace(name: placemark.name ?? address,
                              address: placemark.postalAddress?.street,
                              coordinate: PTMapCoordinate(latitude: location.coordinate.latitude,
                                                          longitude: location.coordinate.longitude))
        }
    }

    public func search(query: String, region: PTMapRegion? = nil) async throws -> [PTMapPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region {
            request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: region.center.latitude,
                                                                                longitude: region.center.longitude),
                                                 span: MKCoordinateSpan(latitudeDelta: region.latitudeDelta,
                                                                        longitudeDelta: region.longitudeDelta))
        }
        let response = try await MKLocalSearch(request: request).start()
        return response.mapItems.compactMap { (item: MKMapItem) -> PTMapPlace? in
            guard let coordinate = item.placemark.location?.coordinate else { return nil }
            return PTMapPlace(name: item.name ?? query,
                              address: item.placemark.postalAddress?.street,
                              coordinate: PTMapCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude))
        }
    }

    public func route(from start: PTMapCoordinate, to end: PTMapCoordinate, transport: MKDirectionsTransportType = .automobile) async throws -> PTMapRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: start.latitude, longitude: start.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: end.latitude, longitude: end.longitude)))
        request.transportType = transport
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else { throw PTMapError.notFound }
        let points = route.polyline.points()
        let coordinates = (0..<route.polyline.pointCount).map { index -> PTMapCoordinate in
            let coordinate = points[index].coordinate
            return PTMapCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        return PTMapRoute(distance: route.distance,
                          expectedTravelTime: route.expectedTravelTime,
                          coordinates: coordinates)
    }

    #if canImport(UIKit)
    public func snapshot(region: PTMapRegion, size: CGSize) async throws -> UIImage {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: region.center.latitude,
                                                                            longitude: region.center.longitude),
                                             span: MKCoordinateSpan(latitudeDelta: region.latitudeDelta,
                                                                    longitudeDelta: region.longitudeDelta))
        options.size = size
        return try await withCheckedThrowingContinuation { continuation in
            MKMapSnapshotter(options: options).start { snapshot, error in
                if let error { continuation.resume(throwing: error) }
                else if let snapshot { continuation.resume(returning: snapshot.image) }
                else { continuation.resume(throwing: PTMapError.unavailable) }
            }
        }
    }
    #endif

    public func openInAppleMaps(_ place: PTMapPlace) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: place.coordinate.latitude,
                                                                                       longitude: place.coordinate.longitude)))
        item.name = place.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}
