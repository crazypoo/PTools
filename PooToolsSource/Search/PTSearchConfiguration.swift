//
//  PTSearchConfiguration.swift
//  PooTools
//
// English: Immutable-friendly search configuration shared by the MainActor controller.
// Español: Configuración de búsqueda preparada para valores inmutables y compartida por el controlador MainActor.
// 中文：由 MainActor 控制器使用的、适合保持不可变的搜索配置。
//

import Foundation

#if SWIFT_PACKAGE
import PooToolsSearchBar
#endif

public struct PTSearchConfiguration: Sendable, Equatable {
    public var minimumCharacters: Int
    public var debounceInterval: Duration
    public var searchWhileTyping: Bool
    public var searchOnReturn: Bool
    public var clearOnCancel: Bool
    public var clearOnEmptyKeyword: Bool
    public var keepsPreviousResultsWhileLoading: Bool
    public var showsCancelButton: Bool
    public var dismissKeyboardOnScroll: Bool
    public var dismissKeyboardOnSelection: Bool
    public var automaticallyShowsHistory: Bool
    public var automaticallyShowsSuggestions: Bool
    public var enablesPagination: Bool
    public var enablesRefresh: Bool
    public var paginationPageSize: Int
    public var historyMaximumCount: Int
    // English: Controls the content height of the embedded search bar.
    // Español: Controla la altura de contenido de la barra de búsqueda integrada.
    // 中文：控制内嵌搜索框的内容高度。
    public var searchBarHeight: CGFloat
    public var mode: PTSearchMode
    public var placement: PTSearchPlacement
    public var visualStyle: PTSearchVisualStyle

    // English: Preserve the 5.64.4 initializer while keeping the new search-bar height opt-in.
    // Español: Conserva el inicializador de 5.64.4 y mantiene opcional la nueva altura de la barra.
    // 中文：保留 5.64.4 初始化器，同时让新的搜索框高度配置保持可选。
    @_disfavoredOverload
    public init(minimumCharacters: Int = 1,
                debounceInterval: Duration = .milliseconds(300),
                searchWhileTyping: Bool = true,
                searchOnReturn: Bool = true,
                clearOnCancel: Bool = true,
                clearOnEmptyKeyword: Bool = true,
                keepsPreviousResultsWhileLoading: Bool = true,
                showsCancelButton: Bool = true,
                dismissKeyboardOnScroll: Bool = true,
                dismissKeyboardOnSelection: Bool = true,
                automaticallyShowsHistory: Bool = true,
                automaticallyShowsSuggestions: Bool = false,
                enablesPagination: Bool = false,
                enablesRefresh: Bool = false,
                paginationPageSize: Int = 20,
                historyMaximumCount: Int = 20,
                mode: PTSearchMode = .custom,
                placement: PTSearchPlacement = .contentTop,
                visualStyle: PTSearchVisualStyle = .automatic) {
        self.init(minimumCharacters: minimumCharacters,
                  debounceInterval: debounceInterval,
                  searchWhileTyping: searchWhileTyping,
                  searchOnReturn: searchOnReturn,
                  clearOnCancel: clearOnCancel,
                  clearOnEmptyKeyword: clearOnEmptyKeyword,
                  keepsPreviousResultsWhileLoading: keepsPreviousResultsWhileLoading,
                  showsCancelButton: showsCancelButton,
                  dismissKeyboardOnScroll: dismissKeyboardOnScroll,
                  dismissKeyboardOnSelection: dismissKeyboardOnSelection,
                  automaticallyShowsHistory: automaticallyShowsHistory,
                  automaticallyShowsSuggestions: automaticallyShowsSuggestions,
                  enablesPagination: enablesPagination,
                  enablesRefresh: enablesRefresh,
                  paginationPageSize: paginationPageSize,
                  historyMaximumCount: historyMaximumCount,
                  mode: mode,
                  placement: placement,
                  visualStyle: visualStyle,
                  searchBarHeight: 32)
    }

    public init(minimumCharacters: Int = 1,
                debounceInterval: Duration = .milliseconds(300),
                searchWhileTyping: Bool = true,
                searchOnReturn: Bool = true,
                clearOnCancel: Bool = true,
                clearOnEmptyKeyword: Bool = true,
                keepsPreviousResultsWhileLoading: Bool = true,
                showsCancelButton: Bool = true,
                dismissKeyboardOnScroll: Bool = true,
                dismissKeyboardOnSelection: Bool = true,
                automaticallyShowsHistory: Bool = true,
                automaticallyShowsSuggestions: Bool = false,
                enablesPagination: Bool = false,
                enablesRefresh: Bool = false,
                paginationPageSize: Int = 20,
                historyMaximumCount: Int = 20,
                mode: PTSearchMode = .custom,
                placement: PTSearchPlacement = .contentTop,
                visualStyle: PTSearchVisualStyle = .automatic,
                searchBarHeight: CGFloat = 32) {
        self.minimumCharacters = max(0, minimumCharacters)
        self.debounceInterval = debounceInterval
        self.searchWhileTyping = searchWhileTyping
        self.searchOnReturn = searchOnReturn
        self.clearOnCancel = clearOnCancel
        self.clearOnEmptyKeyword = clearOnEmptyKeyword
        self.keepsPreviousResultsWhileLoading = keepsPreviousResultsWhileLoading
        self.showsCancelButton = showsCancelButton
        self.dismissKeyboardOnScroll = dismissKeyboardOnScroll
        self.dismissKeyboardOnSelection = dismissKeyboardOnSelection
        self.automaticallyShowsHistory = automaticallyShowsHistory
        self.automaticallyShowsSuggestions = automaticallyShowsSuggestions
        self.enablesPagination = enablesPagination
        self.enablesRefresh = enablesRefresh
        self.paginationPageSize = max(1, paginationPageSize)
        self.historyMaximumCount = max(1, historyMaximumCount)
        self.searchBarHeight = max(32, searchBarHeight)
        self.mode = mode
        self.placement = placement
        self.visualStyle = visualStyle
    }

    public static var standard: PTSearchConfiguration {
        PTSearchConfiguration()
    }

    public static var localSearch: PTSearchConfiguration {
        PTSearchConfiguration(minimumCharacters: 1,
                              debounceInterval: .milliseconds(120),
                              searchWhileTyping: true,
                              automaticallyShowsHistory: true,
                              mode: .local)
    }

    public static var remoteSearch: PTSearchConfiguration {
        PTSearchConfiguration(minimumCharacters: 1,
                              debounceInterval: .milliseconds(350),
                              searchWhileTyping: true,
                              keepsPreviousResultsWhileLoading: true,
                              enablesPagination: true,
                              enablesRefresh: true,
                              mode: .remote)
    }

    public static var instantSearch: PTSearchConfiguration {
        PTSearchConfiguration(minimumCharacters: 0,
                              debounceInterval: .milliseconds(80),
                              searchWhileTyping: true,
                              automaticallyShowsHistory: false,
                              mode: .local)
    }

    public var debounceTimeInterval: TimeInterval {
        let components = debounceInterval.components
        let seconds = TimeInterval(components.seconds)
        let attoseconds = TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
        return max(0, seconds + attoseconds)
    }
}
