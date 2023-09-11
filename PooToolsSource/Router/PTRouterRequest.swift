//
//  PTRouterRequest.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

class PTRouterRequest: PTRouterParser {
    
    var urlString: String
    var sheme: String
    var paths: [String]
    var queries: [String: Any]
    
    init(_ urlString: String) {
        self.urlString = urlString
        self.sheme = PTRouterRequest.parserSheme(urlString)
        
        let result = PTRouterRequest.parser(urlString)
        self.paths = result.paths
        self.queries = result.queries
    }
    
}
