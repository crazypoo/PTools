//
//  UIDataDetectorTypes+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIDataDetectorTypes: CustomStringConvertible {
    public var description: String {
        switch self {
        case .phoneNumber:
            return "Phone Number"

        case .link:
            return "Link"

        case .address:
            return "Address"

        case .calendarEvent:
            return "Calendar Event"

        case .shipmentTrackingNumber:
            return "Shipment Tracking Number"

        case .flightNumber:
            return "Flight Number"

        case .lookupSuggestion:
            return "Lookup Suggestion"

        case .all:
            return "All"

        default:
            return "\(self) (unsupported)"
        }
    }
}
