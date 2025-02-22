//
//  PTRouterPattern.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/9/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

public class PTRouterPattern: PTRouterParser {
    
    public static let PatternPlaceHolder = "~PT~"
    
    public var patternString: String
    public var sheme: String
    public var patternPaths: [String]
    public var priority: uint
    public var matchString: String
    public var classString: String
    public var paramsMatchDict: [String: Int]
    
    public init(_ string: String,
                _ classString: String,
                priority: uint = 0) {
        
        self.patternString = string
        self.priority = priority
        self.sheme = PTRouterPattern.parserSheme(string)
        self.patternPaths = PTRouterPattern.parserPaths(string)
        self.paramsMatchDict = [String: Int]()
        self.classString = classString
        var matchPaths = [String]()
        for i in 0..<patternPaths.count {
            var pathComponent = self.patternPaths[i]
            if pathComponent.hasPrefix(":") {
                let name = pathComponent.dropFirst(1)
                self.paramsMatchDict[name] = i
                pathComponent = PTRouterPattern.PatternPlaceHolder
            }
            matchPaths.append(pathComponent)
        }
        self.matchString = matchPaths.joined(separator: "/")
    }
}
