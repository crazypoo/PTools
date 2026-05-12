//
//  PTUserDefaultKeysAndValues.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 23/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

class PTUserDefaultKeysAndValues: NSObject {
    static let shares = PTUserDefaultKeysAndValues()
    
    var showAllUserDefaultsKeys:Bool = false
    
    func keyAndValues() -> [[String:Any]] {
        var kAndV = [[String:Any]]()
        let keys: [String] = {
            
            if showAllUserDefaultsKeys {
                return UserDefaults.standard.dictionaryRepresentation().map { $0.key }
            }
            
            // Show keys the developer has added to the app (+ LocalConsole keys), excluding all of Apple's keys.
            if let bundle: String = Bundle.main.bundleIdentifier {
                let preferencePath: String = NSHomeDirectory() + "/Library/Preferences/\(bundle).plist"
                
                let _keys = NSDictionary(contentsOfFile: preferencePath)?.allKeys as! [String]
                
                return _keys.filter {
                    !$0.contains("LocalConsole.")
                }
            }
            
            return []
        }()
        
        for key in keys.sorted(by: { $0.lowercased() < $1.lowercased() }) {
            guard !key.contains("LocalConsole_") else {
                UserDefaults.standard.removeObject(forKey: key)
                continue
            }
            
            if let value = UserDefaults.standard.value(forKey: key) {
                kAndV.append([key:value])
            }
        }
        return kAndV
    }
}
