//
//  PTViewToPDF.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/26.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import CoreGraphics

public class PTViewToPDF: NSObject {

    static func generatePDF(with pages: [UIView]) -> String? {
        let tempDirectory = FileManager.pt.TmpDirectory()
        let filepath = tempDirectory.appendingPathComponent("temp.pdf")
        
        UIGraphicsBeginPDFContextToFile(filepath, CGRect.zero, nil)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        
        for page in pages {
            drawPage(page, withContext: context)
        }
        
        UIGraphicsEndPDFContext()
        
        return filepath
    }
    
    static func drawPage(_ page: UIView, withContext context: CGContext) {
        UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0.0, y: 0.0, width: page.bounds.size.width, height: page.bounds.size.height), nil)
        
        for subview in allSubViews(for: page) {
            if let imageView = subview as? UIImageView {
                imageView.image?.draw(in: imageView.frame)
            } else if let label = subview as? UILabel {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = label.lineBreakMode
                paragraphStyle.alignment = label.textAlignment
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: label.font as Any,
                    .paragraphStyle: paragraphStyle,
                    .foregroundColor: label.textColor as Any
                ]
                
                label.text?.draw(in: label.frame, withAttributes: attributes)
            } else {
                drawLines(using: subview, withLineThickness: 1.0, in: context, fillView: subview.tag != 0)
            }
        }
    }
    
    static func drawLines(using view: UIView, withLineThickness thickness: CGFloat, in context: CGContext, fillView: Bool) {
        context.saveGState()
        context.setStrokeColor(view.backgroundColor?.cgColor ?? UIColor.clear.cgColor)
        context.setFillColor(view.backgroundColor?.cgColor ?? UIColor.clear.cgColor)
        context.setLineWidth(thickness)
        
        if view.frame.size.width > 1 && view.frame.size.height == 1 {
            context.move(to: CGPoint(x: view.frame.origin.x - 0.5, y: view.frame.origin.y))
            context.addLine(to: CGPoint(x: view.frame.origin.x + view.frame.size.width - 0.5, y: view.frame.origin.y))
            context.strokePath()
        } else if view.frame.size.width == 1 && view.frame.size.height > 1 {
            context.move(to: CGPoint(x: view.frame.origin.x, y: view.frame.origin.y - 0.5))
            context.addLine(to: CGPoint(x: view.frame.origin.x, y: view.frame.origin.y + view.frame.size.height + 0.5))
            context.strokePath()
        } else if view.frame.size.width > 1 && view.frame.size.height > 1 {
            if fillView {
                context.setFillColor(view.backgroundColor?.cgColor ?? UIColor.clear.cgColor)
                context.fill(view.frame)
            }
            context.stroke(view.frame)
        }
        
        context.restoreGState()
    }
    
    static func allSubViews(for page: UIView) -> [UIView] {
        var array: [UIView] = [page]
        
        for subview in page.subviews {
            if let label = subview as? UILabel {
                label.sizeToFit()
                label.layoutIfNeeded()
            }
            
            let origin = subview.superview?.convert(subview.frame.origin, to: subview.superview?.superview) ?? .zero
            subview.frame = CGRect(origin: origin, size: subview.frame.size)
            array.append(contentsOf: allSubViews(for: subview))
        }
        
        return array
    }
}
