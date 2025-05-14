//
//  PTPageControllable.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/14/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

public protocol PTPageControllable : AnyObject {
    var currentPage: Int { get }
    func setCurrentPage(index: Int)
    func update(currentPage: Int, totalPages: Int)
}

extension UIPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.currentPage = index
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.currentPage = currentPage
        self.numberOfPages = totalPages
    }
}

extension PTFilledPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

extension PTPillPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

extension PTSnakePageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}

extension PTScrollingPageControl: PTPageControllable {
    public func setCurrentPage(index: Int) {
        self.progress = CGFloat(index)
    }
    
    public func update(currentPage: Int, totalPages: Int) {
        self.progress = CGFloat(currentPage)
        self.pageCount = totalPages
    }
}
