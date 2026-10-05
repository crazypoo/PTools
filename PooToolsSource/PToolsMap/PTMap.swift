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

    public func reverseGeocode(coordinate: PTMapCoordinate) async throws -> [PTMapPlace] {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.map { placemark in
            PTMapPlace(name: placemark.name ?? placemark.locality ?? "",
                       address: placemark.postalAddress?.street,
                       coordinate: coordinate)
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

    public func searchResult(query: String, region: PTMapRegion? = nil) async throws -> PTMapSearchResult {
        PTMapSearchResult(query: query, places: try await search(query: query, region: region))
    }

    public func route(from start: PTMapCoordinate,
                      to end: PTMapCoordinate,
                      transport: PTMapTransport) async throws -> PTMapRoute {
        try await route(from: start, to: end, transport: Self.directionsTransport(for: transport))
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

    public func routeDetails(from start: PTMapCoordinate,
                             to end: PTMapCoordinate,
                             transport: MKDirectionsTransportType = .automobile) async throws -> PTMapRouteDetails {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: start.latitude,
                                                                                              longitude: start.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: end.latitude,
                                                                                                   longitude: end.longitude)))
        request.transportType = transport
        request.requestsAlternateRoutes = true
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else { throw PTMapError.notFound }
        let coordinates = route.polyline.points()
        let routeCoordinates = (0..<route.polyline.pointCount).map { coordinates[$0].coordinate }
            .map { PTMapCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
        let steps = route.steps.map { step in
            let points = step.polyline.points()
            let stepCoordinates = (0..<step.polyline.pointCount).map { points[$0].coordinate }
                .map { PTMapCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
            return PTMapRouteStep(instruction: step.instructions,
                                  distance: step.distance,
                                  expectedTravelTime: route.distance > 0
                                    ? route.expectedTravelTime * step.distance / route.distance
                                    : 0,
                                  coordinates: stepCoordinates)
        }
        let value = PTMapRoute(distance: route.distance,
                               expectedTravelTime: route.expectedTravelTime,
                               coordinates: routeCoordinates)
        let alternatives = response.routes.dropFirst().map { alternate in
            let points = alternate.polyline.points()
            let alternateCoordinates = (0..<alternate.polyline.pointCount).map { points[$0].coordinate }
                .map { PTMapCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
            return PTMapRoute(distance: alternate.distance,
                              expectedTravelTime: alternate.expectedTravelTime,
                              coordinates: alternateCoordinates)
        }
        return PTMapRouteDetails(route: value,
                                 eta: PTMapETA(distance: route.distance,
                                               expectedTravelTime: route.expectedTravelTime),
                                 steps: steps,
                                 alternatives: alternatives)
    }

    public func routeDetails(from start: PTMapCoordinate,
                             to end: PTMapCoordinate,
                             transport: PTMapTransport) async throws -> PTMapRouteDetails {
        try await routeDetails(from: start,
                               to: end,
                               transport: Self.directionsTransport(for: transport))
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

    public func externalMapURL(provider: PTMapExternalProvider,
                                destination: PTMapCoordinate,
                                label: String? = nil) -> URL? {
        let latitude = destination.latitude
        let longitude = destination.longitude
        switch provider {
        case .apple:
            var components = URLComponents(string: "http://maps.apple.com/")
            components?.queryItems = [URLQueryItem(name: "ll", value: "\(latitude),\(longitude)"),
                                      URLQueryItem(name: "q", value: label)]
            return components?.url
        case .google:
            var components = URLComponents(string: "comgooglemaps://")
            components?.queryItems = [URLQueryItem(name: "center", value: "\(latitude),\(longitude)"),
                                      URLQueryItem(name: "q", value: label)]
            return components?.url
        case .googleUniversalLink:
            var components = URLComponents(string: "https://www.google.com/maps/dir/")
            components?.queryItems = [URLQueryItem(name: "api", value: "1"),
                                      URLQueryItem(name: "destination", value: "\(latitude),\(longitude)"),
                                      URLQueryItem(name: "destination_place_id", value: label)]
            return components?.url
        }
    }

    private static func directionsTransport(for transport: PTMapTransport) -> MKDirectionsTransportType {
        switch transport {
        case .automobile: return .automobile
        case .walking: return .walking
        case .transit: return .transit
        case .cycling: return .walking
        }
    }
}

#if canImport(UIKit)
// English: A small UIKit adapter renders typed annotations and routes without owning location permission.
// Español: Un adaptador UIKit pequeño dibuja anotaciones y rutas tipadas sin poseer permisos de ubicación.
// 中文：轻量 UIKit 适配器负责绘制类型化标注和路线，不接管定位权限。
@MainActor
public final class PTMapViewAdapter: NSObject {
    public let mapView: MKMapView

    public init(mapView: MKMapView = MKMapView(frame: .zero)) {
        self.mapView = mapView
        super.init()
    }

    public func render(annotations: [PTMapAnnotation], route: PTMapRoute? = nil) {
        mapView.removeAnnotations(mapView.annotations)
        let values = annotations.map { annotation -> MKPointAnnotation in
            let value = MKPointAnnotation()
            value.coordinate = CLLocationCoordinate2D(latitude: annotation.coordinate.latitude,
                                                      longitude: annotation.coordinate.longitude)
            value.title = annotation.title
            value.subtitle = annotation.subtitle
            return value
        }
        mapView.addAnnotations(values)
        mapView.removeOverlays(mapView.overlays)
        guard let route, !route.coordinates.isEmpty else { return }
        var coordinates = route.coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude,
                                                                          longitude: $0.longitude) }
        let overlay = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        mapView.addOverlay(overlay)
    }
}
#endif
