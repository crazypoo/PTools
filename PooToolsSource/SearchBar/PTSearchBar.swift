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
    
    // MARK: - 🎨 UI 属性配置
    open var searchPlaceholder: String = "PT Input text".localized() { didSet { updateTextUI() } }
    open var searchPlaceholderFont: UIFont = .systemFont(ofSize: 16) { didSet { updateTextUI() } }
    open var searchBarTextFieldBorderColor: UIColor = UIColor.random { didSet { updateBorderUI() } }
    open var cursorColor: UIColor = .lightGray { didSet { updateTextUI() } }
    open var searchPlaceholderColor: UIColor = UIColor.random { didSet { updateTextUI() } }
    open var searchTextColor: UIColor = UIColor.random { didSet { updateTextUI() } }
    open var searchBarOutViewColor: UIColor = UIColor.random { didSet { updateBackgroundUI() } }
    open var searchBarTextFieldCornerRadius: CGFloat = 5 { didSet { updateBorderUI() } }
    open var searchBarTextFieldBorderWidth: CGFloat = 0.5 { didSet { updateBorderUI() } }
    open var searchTextFieldBackgroundColor: UIColor = UIColor.random { didSet { updateTextUI() } }
    
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
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        // layoutSubviews 中只做真正需要随 frame 变化而变化的操作
        // 例如设置圆角等依赖 bounds 的操作
        updateBorderUI()
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
        guard let clearImage = searchBarImage else { return }
        
        // 计算目标高度
        let clearTopSpace = min(max(searchImageTopSpacing, 0), self.frame.height * 0.5)
        let clearHeight = max(self.frame.height - clearTopSpace * 2, 16) // 给一个最小保护值
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await PTLoadImageFunction.loadImage(contentData: clearImage)
            self.processAndSetImage(result: result, targetHeight: clearHeight, iconState: .search)
        }
    }
    
    /// 异步加载清除按钮图标
    private func loadClearImage() {
        guard let config = clearConfig, let clearImage = config.clearImage else { return }
        
        let clearTopSpace = min(max(config.clearTopSpace, 0), self.frame.height * 0.5)
        let clearHeight = max(self.frame.height - clearTopSpace * 2, 16)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let result = await PTLoadImageFunction.loadImage(contentData: clearImage)
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
        guard let _ = clearConfig else { return }
        
        // 方案: 监听 UITextField 的 .editingChanged 事件来捕获清除行为
        // 虽然直接拿 _clearButton 绑定事件可以做到，但容易失效。
        // 由于当用户点击原生清除按钮时，UITextField 会发出 text 改变的通知。
        guard let searchTextField = safeSearchTextField else { return }
        
        // 先移除旧的以防重复绑定
        searchTextField.removeTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // 如果文本变为了空，说明用户点击了 clear 按钮（或手动删光了）
        // 触发你配置的回调
        if textField.text?.isEmpty == true {
            clearConfig?.clearAction?()
        }
    }
}
