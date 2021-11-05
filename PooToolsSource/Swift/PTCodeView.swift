//
//  PTCodeView.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/28.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTCodeView: UIView {
    
    private let alphabetArr = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    
    private var numberOfCode = 0
    private var numberOfLine = 0
    private var changeTime : TimeInterval = 0
    private var dataSource = [String]()
    private var changeString = ""

    public var codeBlock:((_ codeView:PTCodeView, _ code:String)->Void)?

    private var dismiss : Bool? = false
    
    deinit {
        self.removeFromSuperview()
    }

    public init(frame: CGRect,numberOfCodes:Int,numberOfLines:Int,changeTimes:TimeInterval)
    {
        super.init(frame: frame)
        
        for index in 0..<10
        {
            dataSource.append(String(format: "%d", index))
        }
        alphabetArr.enumerated().forEach { (index,value) in
            dataSource.append(value)
        }
        alphabetArr.enumerated().forEach { (index,value) in
            dataSource.append(value.lowercased())
        }
        numberOfCode = numberOfCodes
        numberOfLine = numberOfLines
        changeTime = changeTimes
        changeResultString()
        self.backgroundColor = UIColor.randomColor
        if changeTimes != 0
        {
            timeChange()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func removeFromSuperview() {
        super.removeFromSuperview()
        self.dismiss = true
    }

    private func timeChange()
    {
        var newCount = Int(changeTime) + 1
        let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler {
            DispatchQueue.main.async {
                newCount -= 1
                if newCount < 1 {
                    DispatchQueue.main.async {
                        if !self.dismiss!
                        {
                            timer.suspend()
                            self.timeChange()
                            self.changeResultString()
                        }
                        else
                        {
                            timer.suspend()
                        }
                    }
                    timer.cancel()
                }
            }
        }
        timer.resume()
    }
        
    public func changeCode()
    {
        changeResultString()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        changeResultString()
    }

    private func changeResultString()
    {
        let tempString = NSMutableString()
        for i in 0..<numberOfCode {
            print(">>>>>\(i)")
            let index = arc4random() % UInt32(dataSource.count - 1)
            tempString.append(dataSource[Int(index)])
        }
        changeString = String(format: "%@", tempString)
        if codeBlock != nil
        {
            codeBlock!(self,changeString)
        }
        self.setNeedsDisplay()
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let cSize = ("S" as NSString).size(withAttributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 20)])
        let width = rect.size.width / CGFloat(changeString.charactersArray.count) - cSize.width
        let height = rect.size.height - cSize.height
        var point : CGPoint?
        var pX : CGFloat?
        var pY : CGFloat?

        for i in 0..<changeString.charactersArray.count {
            pX = CGFloat(arc4random() % UInt32(width)) + rect.size.width / CGFloat(changeString.charactersArray.count) * CGFloat(i)
            pY = CGFloat(arc4random() % UInt32(height))
            point = CGPoint(x: pX!,y: pY!)
            let c : NSString = NSString(format: "%C", (changeString as NSString).character(at: i))
            c.draw(at: point!, withAttributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize: 20),NSAttributedString.Key.foregroundColor:UIColor.randomColor])
        }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1)
        for count in 0..<numberOfLine {
            print("count>>>>>>>>>>>>>>>>>>>\(count)")
            context?.setStrokeColor(UIColor.randomColor.cgColor)
            pX = CGFloat(arc4random() % UInt32(rect.size.width))
            pY = CGFloat(arc4random() % UInt32(rect.size.height))
            point = CGPoint(x: pX!,y: pY!)
            context?.move(to: point!)
            pX = CGFloat(arc4random() % UInt32(rect.size.width))
            pY = CGFloat(arc4random() % UInt32(rect.size.height))
            point = CGPoint(x: pX!,y: pY!)
            context?.addLine(to: point!)
            context?.strokePath()
        }
    }
}
