//
//  PTSearchPlacement.swift
//  PooTools
//
// English: Search placement describes only presentation; it never changes the search pipeline.
// Español: La ubicación de búsqueda solo describe la presentación; nunca cambia la canalización.
// 中文：搜索位置只描述展示方式，不改变搜索管线。
//

import Foundation

public enum PTSearchPlacement: Sendable, Equatable {
    case contentTop
    case navigationBar
    case navigationBarExpanded
    case custom
}
