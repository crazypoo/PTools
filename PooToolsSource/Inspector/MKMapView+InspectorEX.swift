//
//  MKMapView+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import MapKit

extension MKMapType: @retroactive CaseIterable {
    public typealias AllCases = [MKMapType]

    public static let allCases: [MKMapType] = [
        .standard,
        .satellite,
        .hybrid,
        .satelliteFlyover,
        .hybridFlyover,
        .mutedStandard
    ]
}

extension MKMapType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .standard:
            return "Standard"

        case .satellite:
            return "Satellite"

        case .hybrid:
            return "Hybrid"

        case .satelliteFlyover:
            return "Satellite Flyover"

        case .hybridFlyover:
            return "Hybrid Flyover"

        case .mutedStandard:
            return "Muted Standard"

        @unknown default:
            return "\(self) (unsupported)"
        }
    }
}
