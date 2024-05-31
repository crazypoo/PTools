//
//  PTDebugLocationKit.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreLocation

final class PTDebugLocationKit {
    static let shared = PTDebugLocationKit()

    var simulatedLocation: CLLocation? {
        get {
            let latitude = PTCoreUserDefultsWrapper.PTMockLocationLat
            let longitude = PTCoreUserDefultsWrapper.PTMockLocationLng
            guard !latitude.isZero, !longitude.isZero else { return nil }

            return .init(latitude: latitude, longitude: longitude)
        }
        set {
            if let location = newValue {
                PTCoreUserDefultsWrapper.PTMockLocationLat = location.coordinate.latitude
                PTCoreUserDefultsWrapper.PTMockLocationLng = location.coordinate.longitude
            } else {
                PTCoreUserDefultsWrapper.PTMockLocationLat = 0
                PTCoreUserDefultsWrapper.PTMockLocationLng = 0
            }
        }
    }

    var indexSaved: Int {
        guard let simulatedLocation else { return -1 }
        if let index = presetLocations.firstIndex(
            where: {
                $0.latitude == simulatedLocation.coordinate.latitude &&
                    $0.longitude == simulatedLocation.coordinate.longitude
            }
        ) {
            return index + 1
        }

        return -1
    }

    let presetLocations: [PresetLocation] = {
        var presetLocations = [PresetLocation]()
        presetLocations.append(PresetLocation(title: "London, England", latitude: 51.509980, longitude: -0.133700))
        presetLocations.append(PresetLocation(title: "Johannesburg, South Africa", latitude: -26.204103,longitude: 28.047305))
        presetLocations.append(PresetLocation(title: "Moscow, Russia", latitude: 55.755786, longitude: 37.617633))
        presetLocations.append(PresetLocation(title: "Mumbai, India", latitude: 19.017615, longitude: 72.856164))
        presetLocations.append(PresetLocation(title: "Tokyo, Japan", latitude: 35.702069, longitude: 139.775327))
        presetLocations.append(PresetLocation(title: "Sydney, Australia", latitude: -33.863400, longitude: 151.211000))
        presetLocations.append(PresetLocation(title: "Hong Kong, China", latitude: 22.284681, longitude: 114.158177))
        presetLocations.append(PresetLocation(title: "Honolulu, HI, USA", latitude: 21.282778, longitude: -157.829444))
        presetLocations.append(PresetLocation(title: "San Francisco, CA, USA", latitude: 37.787359, longitude: -122.408227))
        presetLocations.append(PresetLocation(title: "Mexico City, Mexico", latitude: 19.435478, longitude: -99.136479))
        presetLocations.append(PresetLocation(title: "New York, NY, USA", latitude: 40.759211, longitude: -73.984638))
        presetLocations.append(PresetLocation(title: "Rio de Janeiro, Brazil", latitude: -22.903539, longitude: -43.209587))

        return presetLocations
    }()
}

final class PresetLocation {
    var title: String
    var latitude: Double
    var longitude: Double

    init(title: String, latitude: Double, longitude: Double) {
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
    }
}

