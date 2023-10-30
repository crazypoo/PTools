//
//  PTPermission.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

open class PTPermission {
    
    open var authorized: Bool {
        status == .authorized
    }
    
    open var denied: Bool {
        status == .denied
    }
    
    open var notDetermined: Bool {
        status == .notDetermined
    }
    
    open var debugName: String {
        kind.name
    }
    
    open var localisedName: String {
        PTPermissionText.permission_name(for: kind)
    }
    
    /**
     PermissionsKit: Open settings page.
     For most permissions its app page in settings app.
     You can overide it if your permission need open custom page.
     */
    @available(iOSApplicationExtension, unavailable)
    open func openSettingPage() {
        DispatchQueue.main.async {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
    }
    
    // MARK: Must Ovveride
    
    open var kind: PTPermission.Kind {
        preconditionFailure("This method must be overridden.")
    }
    
    open var status: PTPermission.Status {
        preconditionFailure("This method must be overridden.")
    }
    
    open func request(completion: @escaping ()->Void) {
        preconditionFailure("This method must be overridden.")
    }
    
    open var canBePresentWithCustomInterface: Bool {
        true
    }
    
    // MARK: Internal
    
    public init() {}
    
    // MARK: - Models
    
    @objc public enum Status: Int, CustomStringConvertible {
        
        case authorized
        case denied
        case notDetermined
        case notSupported
        
        public var description: String {
            switch self {
            case .authorized: return "authorized"
            case .denied: return "denied"
            case .notDetermined: return "not determined"
            case .notSupported: return "not supported"
            }
        }
    }
    
    public enum Kind {
        
        case camera
        case notification
        case photoLibrary
        case microphone
        case calendar(access: CalendarAccess)
        case contacts
        case reminders
        case speech
        case location(access: LocationAccess)
        case motion
        case mediaLibrary
        case bluetooth
        case tracking
        case faceID
        case siri
        case health
        
        public var name: String {
            switch self {
            case .camera:
                return "Camera"
            case .photoLibrary:
                return "Photo Library"
            case .microphone:
                return "Microphone"
            case .calendar(access: .write):
                return "Calendar Only Write"
            case .calendar(access: .full):
                return "Calendar"
            case .contacts:
                return "Contacts"
            case .reminders:
                return "Reminders"
            case .speech:
                return "Speech"
            case .location(access: .always):
                return "Location Always"
            case .location(access: .whenInUse):
                return "Location When Use"
            case .motion:
                return "Motion"
            case .mediaLibrary:
                return "Media Library"
            case .bluetooth:
                return "Bluetooth"
            case .notification:
                return "Notification"
            case .tracking:
                return "Tracking"
            case .faceID:
                return "FaceID"
            case .siri:
                return "Siri"
            case .health:
                return "Health"
            }
        }
    }
    
    public enum CalendarAccess {
        
        case full
        case write
    }
    
    public enum LocationAccess {
        
        case whenInUse
        case always
    }
}
