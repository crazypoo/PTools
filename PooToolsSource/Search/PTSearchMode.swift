//
//  PTSearchMode.swift
//  PooTools
//
// English: Search modes describe where results come from without changing the UI pipeline.
// Español: Los modos de búsqueda describen el origen de los resultados sin cambiar la canalización de UI.
// 中文：搜索模式只描述结果来源，不改变 UI 管线。
//

import Foundation

public enum PTSearchMode: Sendable, Equatable {
    case local
    case remote
    case hybrid
    case custom
}
