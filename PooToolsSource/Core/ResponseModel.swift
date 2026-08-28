//
//  ResponseModel.swift
//  MiniChatSwift
//
//  Created by 林勇彬 on 2022/5/20.
//  Copyright © 2022 九州所想. All rights reserved.
//

import UIKit
import SmartCodable

// This mutable DTO is decoded before crossing into the MainActor.
// Este DTO mutable se decodifica antes de cruzar al MainActor.
// 这个可变 DTO 只在进入 MainActor 之前负责解码。
struct PTIPInfoPayload: PTCodableModelProtocol, Sendable {
    var lon: Double = 0.0
    var zip: String = ""
    var query: String = ""
    var asBaseic: String = ""
    var isp: String = ""
    var countryCode: String = ""
    var lat: Double = 0.0
    var city: String = ""
    var region: String = ""
    var timezone: String = ""
    var org: String = ""
    var country: String = ""
    var status: String = ""
    var regionName: String = ""

    init() {}

    static func mappingForKey() -> [SmartKeyTransformer]? {
        [CodingKeys.asBaseic <--- "as"]
    }
}

// Immutable IP information that can safely cross an actor boundary.
// Información IP inmutable que puede cruzar un límite de actor de forma segura.
// 可安全跨越 actor 边界的不可变 IP 信息快照。
public struct PTIPInfoSnapshot: Sendable {
    public let lon: Double
    public let zip: String
    public let query: String
    public let asBaseic: String
    public let isp: String
    public let countryCode: String
    public let lat: Double
    public let city: String
    public let region: String
    public let timezone: String
    public let org: String
    public let country: String
    public let status: String
    public let regionName: String

    init(payload: PTIPInfoPayload) {
        lon = payload.lon
        zip = payload.zip
        query = payload.query
        asBaseic = payload.asBaseic
        isp = payload.isp
        countryCode = payload.countryCode
        lat = payload.lat
        city = payload.city
        region = payload.region
        timezone = payload.timezone
        org = payload.org
        country = payload.country
        status = payload.status
        regionName = payload.regionName
    }
}

// The public class remains as a MainActor compatibility adapter for existing callers.
// La clase pública permanece como adaptador de compatibilidad aislado en MainActor.
// 保留公开类，作为现有调用方使用的 MainActor 兼容适配器。
@MainActor
public final class PTIPInfoModel: NSObject {
    public var lon: CGFloat = 0.0
    public var zip: String = ""
    public var query: String = ""
    public var asBaseic: String = ""
    public var isp: String = ""
    public var countryCode: String = ""
    public var lat: CGFloat = 0.0
    public var city: String = ""
    public var region: String = ""
    public var timezone: String = ""
    public var org: String = ""
    public var country: String = ""
    public var status: String = ""
    public var regionName: String = ""
    
    required public override init() {}

    public convenience init(snapshot: PTIPInfoSnapshot) {
        self.init()
        lon = CGFloat(snapshot.lon)
        zip = snapshot.zip
        query = snapshot.query
        asBaseic = snapshot.asBaseic
        isp = snapshot.isp
        countryCode = snapshot.countryCode
        lat = CGFloat(snapshot.lat)
        city = snapshot.city
        region = snapshot.region
        timezone = snapshot.timezone
        org = snapshot.org
        country = snapshot.country
        status = snapshot.status
        regionName = snapshot.regionName
    }

    public func snapshot() -> PTIPInfoSnapshot {
        let payload = PTIPInfoPayload(lon: Double(lon),
                                      zip: zip,
                                      query: query,
                                      asBaseic: asBaseic,
                                      isp: isp,
                                      countryCode: countryCode,
                                      lat: Double(lat),
                                      city: city,
                                      region: region,
                                      timezone: timezone,
                                      org: org,
                                      country: country,
                                      status: status,
                                      regionName: regionName)
        return PTIPInfoSnapshot(payload: payload)
    }
}

private extension PTIPInfoPayload {
    init(lon: Double,
         zip: String,
         query: String,
         asBaseic: String,
         isp: String,
         countryCode: String,
         lat: Double,
         city: String,
         region: String,
         timezone: String,
         org: String,
         country: String,
         status: String,
         regionName: String) {
        self.init()
        self.lon = lon
        self.zip = zip
        self.query = query
        self.asBaseic = asBaseic
        self.isp = isp
        self.countryCode = countryCode
        self.lat = lat
        self.city = city
        self.region = region
        self.timezone = timezone
        self.org = org
        self.country = country
        self.status = status
        self.regionName = regionName
    }
}
