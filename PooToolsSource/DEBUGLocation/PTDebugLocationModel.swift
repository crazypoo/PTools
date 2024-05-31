//
//  PTDebugLocationModel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import CoreLocation
import Foundation

final class PTDebugLocationModel: NSObject {
    var selectedIndex: Int = PTDebugLocationKit.shared.indexSaved

    var locations: [PresetLocation] {
        PTDebugLocationKit.shared.presetLocations
    }

    var customDescription: String? {
        guard customSelected else { return nil }
        return coordinateString(with: PTDebugLocationKit.shared.simulatedLocation)
    }

    var customSelected: Bool {
        guard PTDebugLocationKit.shared.simulatedLocation != nil else { return false }
        return PTDebugLocationKit.shared.indexSaved == -1
    }

    func resetLocation() {
        PTDebugLocationKit.shared.simulatedLocation = nil
        selectedIndex = -1
    }

    func coordinateString(with location: CLLocation?) -> String {
        guard let coordinate = location?.coordinate else { return "" }
        let latitudeDegreesMinutesSeconds = degreesMinutesSeconds(with: coordinate.latitude)
        let latitudeDirectionLetter = coordinate.latitude >= 0 ? "N" : "S"

        let longitudeDegreesMinutesSeconds = degreesMinutesSeconds(with: coordinate.longitude)
        let longitudeDirectionLetter = coordinate.longitude >= 0 ? "E" : "W"

        return String(format: "%@%@, %@%@", latitudeDegreesMinutesSeconds, latitudeDirectionLetter, longitudeDegreesMinutesSeconds, longitudeDirectionLetter)
    }

    func degreesMinutesSeconds(with coordinate: CLLocationDegrees) -> String {
        let seconds = Int(coordinate * 3600)
        let degrees = seconds / 3600
        var remainingSeconds = abs(seconds % 3600)
        let minutes = remainingSeconds / 60
        remainingSeconds %= 60
        return String(format: "%d°%d'%d\"", abs(degrees), minutes, remainingSeconds)
    }
}
