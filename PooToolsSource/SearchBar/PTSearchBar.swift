//
//  PTSearchBar.swift
//  PooTools_Example
//
//  Created by ken lam on 2021/10/27.
//  Copyright © 2021 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTSearchBarTextFieldClearButtonConfig: NSObject {
    public var clearAction: PTActionTask?
    public var clearImage: Any?
    public var clearTopSpace: CGFloat = 2
}

@objcMembers
public class PTSearchBar: UISearchBar {

    private var isRefreshingLocalizedPlaceholder = false
    private var usesDefaultLocalizedPlaceholder = true
    private var searchTask: Task<Void, Never>?
    private var searchGeneration: UInt = 0
    private var searchImageTask: Task<Void, Never>?
    private var clearImageTask: Task<Void, Never>?
    private var previousSearchText = ""
    
    // MARK: - 🎨 UI 属性配置
    open var searchPlaceholder: String = "PT Input text".localized() {
        didSet {
            if !isRefreshingLocalizedPlaceholder {
                usesDefaultLocalizedPlaceholder = false
            }
            updateTextUI()
        }
    }
    open var searchPlaceholderFont: UIFont = .systemFont(ofSize: 16) { didSet { updateTextUI() } }
    open var searchBarTextFieldBorderColor: UIColor = UIColor.random { didSet { updateBorderUI() } }
    open var cursorColor: UIColor = .lightGray { didSet { updateTextUI() } }
    open var searchPlaceholderColor: UIColor = UIColor.random { didSet { updateTextUI() } }
    open var searchTextColor: UIColor = UIColor.random { didSet { updateTextUI() } }
    open var searchBarOutViewColor: UIColor = UIColor.random { didSet { updateBackgroundUI() } }
    open var searchBarTextFieldCornerRadius: CGFloat = 5 { didSet { updateBorderUI() } }
    open var searchBarTextFieldBorderWidth: CGFloat = 0.5 { didSet { updateBorderUI() } }
    open var searchTextFieldBackgroundColor: UIColor = UIColor.random { didSet { updateTextUI() } }

    // English: Debounce text changes before starting an asynchronous search.
    // Español: Aplica debounce a los cambios de texto antes de iniciar una búsqueda asíncrona.
    // 中文：在启动异步搜索前对文本变化执行防抖。
    open var searchDebounceInterval: TimeInterval = 0.3

    // English: The handler is optional so existing delegate-based callers keep their behavior.
    // Español: El controlador es opcional para conservar el comportamiento de los clientes que usan delegate.
    // 中文：搜索处理器保持可选，兼容现有基于 delegate 的调用方。
    @nonobjc open var searchHandler: (@MainActor @Sendable (String) async -> Void)? {
        didSet {
            let text = safeSearchTextField?.text ?? ""
            if !text.isEmpty {
                scheduleSearch(for: text)
            }
        }
    }

    // English: Expose the in-flight state without exposing the task itself.
    // Español: Expone el estado en curso sin exponer la tarea interna.
    // 中文：只暴露加载状态，不暴露内部任务。
    public private(set) var isSearching = false {
        didSet { updateLoadingAccessibility() }
    }
    
    open var searchImageTopSpacing: CGFloat = 2
    open var searchBarImage: Any? {
        didSet { loadSearchImage() }
    }
    
    open var clearConfig: PTSearchBarTextFieldClearButtonConfig? {
        didSet {
            loadClearImage()
            setupClearAction()
        }
    }
    
    // MARK: - 🛠 内部属性：安全获取 TextField
    private var safeSearchTextField: UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            return self.value(forKey: "searchField") as? UITextField
        }
    }

    // MARK: - 🚀 生命周期
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    private func initialSetup() {
        // 初始化时统一刷新一次 UI
        updateTextUI()
        updateBackgroundUI()
        updateLoadingAccessibility()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // layoutSubviews 中只做真正需要随 frame 变化而变化的操作
        // 例如设置圆角等依赖 bounds 的操作
        updateBorderUI()
        setupClearAction()
    }
    
    // MARK: - 🖌 私有更新方法
    
    /// 更新文字、颜色等静态 UI（不需要放在 layoutSubviews 中重复执行）
    private func updateTextUI() {
        guard let searchTextField = safeSearchTextField else { return }
        
        searchTextField.backgroundColor = searchTextFieldBackgroundColor
        searchTextField.tintColor = cursorColor
        searchTextField.textColor = searchTextColor
        searchTextField.font = searchPlaceholderFont
        
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: searchPlaceholder,
            attributes: [
                .font: searchPlaceholderFont,
                .foregroundColor: searchPlaceholderColor
            ]
        )
    }
    
    /// 更新边框与圆角
    private func updateBorderUI() {
        guard let searchTextField = safeSearchTextField else { return }
        searchTextField.viewCorner(
            radius: searchBarTextFieldCornerRadius,
            borderWidth: searchBarTextFieldBorderWidth,
            borderColor: searchBarTextFieldBorderColor
        )
    }
    
    /// 更新背景颜色
    private func updateBackgroundUI() {
        backgroundImage = searchBarOutViewColor.createImageWithColor()
    }
    
    // MARK: - 🖼 图片加载逻辑
    
    /// 异步加载放大镜图标
    private func loadSearchImage() {
        searchImageTask?.cancel()
        searchImageTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard let clearImage = self.searchBarImage else { return }
            let clearTopSpace = min(max(self.searchImageTopSpacing, 0), self.frame.height * 0.5)
            let clearHeight = max(self.frame.height - clearTopSpace * 2, 16)
            let result = await PTLoadImageFunction.loadImage(contentData: clearImage)
            guard !Task.isCancelled else { return }
            self.processAndSetImage(result: result, targetHeight: clearHeight, iconState: .search)
        }
    }
    
    /// 异步加载清除按钮图标
    private func loadClearImage() {
        clearImageTask?.cancel()
        guard let config = clearConfig, let clearImage = config.clearImage else { return }
        
        let clearTopSpace = min(max(config.clearTopSpace, 0), self.frame.height * 0.5)
        let clearHeight = max(self.frame.height - clearTopSpace * 2, 16)
        
        clearImageTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await PTLoadImageFunction.loadImage(contentData: clearImage)
            guard !Task.isCancelled else { return }
            // 使用原生的 .clear 状态设置图片，无需手动干预控件大小，系统会自适应我们传入的图片尺寸
            self.processAndSetImage(result: result, targetHeight: clearHeight, iconState: .clear)
        }
    }
    
    /// 通用图片处理与赋值方法
    private func processAndSetImage(result: PTLoadImageResult, targetHeight: CGFloat, iconState: UISearchBar.Icon) {
        // 假设 result 是你的图片加载结果模型 (根据你的代码推导)
        // 注意：如果你代码里的 result 类型有变，请调整此处的动态解析或强转
        let allImages = result.allImages
        let firstImage = result.firstImage
        let loadTime = result.loadTime
        
        let targetSize = CGSize(width: targetHeight, height: targetHeight)
        
        if let images = allImages, !images.isEmpty {
            if images.count > 1 {
                let animatedImg = UIImage.animatedImage(with: images, duration: loadTime)?.transformImage(size: targetSize)
                self.setImage(animatedImg, for: iconState, state: .normal)
            } else if let image = firstImage {
                let reNewImage = image.transformImage(size: targetSize)
                self.setImage(reNewImage, for: iconState, state: .normal)
            } else {
                self.setImage(PTAppBaseConfig.share.defaultEmptyImage, for: iconState, state: .normal)
            }
        }
    }
    
    // MARK: - 🎯 行为绑定
    
    /// 绑定自定义的 Clear 按钮事件
    private func setupClearAction() {
        // 方案: 监听 UITextField 的 .editingChanged 事件来捕获清除行为
        // 虽然直接拿 _clearButton 绑定事件可以做到，但容易失效。
        // 由于当用户点击原生清除按钮时，UITextField 会发出 text 改变的通知。
        guard let searchTextField = safeSearchTextField else { return }
        
        // 先移除旧的以防重复绑定
        searchTextField.removeTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        guard clearConfig != nil else { return }
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        let text = textField.text ?? ""
        if text.isEmpty, !previousSearchText.isEmpty {
            clearConfig?.clearAction?()
        }
        previousSearchText = text
        scheduleSearch(for: text)
    }

    // English: Cancel the pending debounce or the active handler without touching the caller's delegate.
    // Español: Cancela el debounce pendiente o el controlador activo sin modificar el delegate del cliente.
    // 中文：取消待执行的防抖或正在运行的处理器，不干扰调用方 delegate。
    public func cancelSearch() {
        searchGeneration &+= 1
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
    }

    // English: Clear the native field and emit the same editing event as a user action.
    // Español: Limpia el campo nativo y emite el mismo evento de edición que una acción del usuario.
    // 中文：清空原生输入框，并发出与用户操作一致的编辑事件。
    public func clearSearch() {
        guard let textField = safeSearchTextField else { return }
        textField.text = nil
        textField.sendActions(for: .editingChanged)
    }

    // English: Refresh only the default localized placeholder; custom text is never overwritten.
    // Español: Actualiza solo el placeholder localizado predeterminado; nunca sobrescribe el texto personalizado.
    // 中文：只刷新默认本地化占位文字，不覆盖调用方自定义的文字。
    public func refreshLocalizedText() {
        if usesDefaultLocalizedPlaceholder {
            isRefreshingLocalizedPlaceholder = true
            searchPlaceholder = "PT Input text".localized()
            isRefreshingLocalizedPlaceholder = false
        } else {
            updateTextUI()
        }
        accessibilityLabel = searchPlaceholder
    }

    private func scheduleSearch(for query: String) {
        searchGeneration &+= 1
        let generation = searchGeneration
        searchTask?.cancel()
        isSearching = false

        guard let handler = searchHandler, !query.isEmpty else { return }

        let delay = min(max(0, searchDebounceInterval), TimeInterval(UInt64.max) / 1_000_000_000)
        searchTask = Task { @MainActor [weak self] in
            do {
                let nanoseconds = UInt64((delay * 1_000_000_000).rounded(.down))
                try await Task.sleep(nanoseconds: nanoseconds)
            } catch {
                return
            }

            guard let self, !Task.isCancelled, self.searchGeneration == generation else { return }
            self.isSearching = true
            await handler(query)
            guard !Task.isCancelled, self.searchGeneration == generation else { return }
            self.isSearching = false
        }
    }

    private func updateLoadingAccessibility() {
        accessibilityValue = isSearching ? "Loading".localized() : nil
    }
}
