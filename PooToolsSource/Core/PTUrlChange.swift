//
//  PTUrlChange.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public class PTUrlChange: NSObject {
    public class func unicodeURLChange_chinese(url:String)->String
    {
        return url.addingPercentEncoding(withAllowedCharacters: Foundation.CharacterSet.lowercaseLetters)!
    }
    
    public class func getRange(text:String,findText:String)->NSMutableArray
    {
        let arrayRanges = NSMutableArray.init(capacity: 3)
        if (text).stringIsEmpty()
        {
            return NSMutableArray()
        }
        
        let rang : NSRange = (text as NSString).range(of: findText)
        if rang.location != NSNotFound && rang.length != 0
        {
            arrayRanges.add(NSNumber.init(value: rang.location))
            var rang1 = NSRange.init(location: 0, length: 0)
            var location = 0
            var length = 0
            
            var i = 0
            repeat
            {
                if i == 0
                {
                    location = rang.location + rang.length
                    length = rang.length - rang.location - rang.length
                    rang1 = NSRange.init(location: location, length: length)
                }
                else
                {
                    location = rang1.location + rang1.length
                    length = text.charactersArray.count - rang1.location - rang1.length
                    rang1 = NSRange.init(location: location, length: length)
                }
                
                rang1 = (text as NSString).range(of: findText, options: NSString.CompareOptions.caseInsensitive, range: rang1)
                
                if rang1.location == NSNotFound && rang1.length == 0
                {
                    return arrayRanges
                }
                
                arrayRanges.add(NSNumber.init(value: rang1.location))
                
                i += 1
            }  while i == 999999; do {
                
            }
            return arrayRanges
        }
        return arrayRanges
    }
}
